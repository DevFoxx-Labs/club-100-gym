import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';

/// A single aggregated data point for a given period (start-of-month or start-of-year).
class PeriodValue {
  final DateTime period;
  final double value;

  const PeriodValue(this.period, this.value);
}

/// Aggregation granularity for report queries.
enum ReportGranularity { monthly, yearly }

/// Aggregates income (payments), expenses, and member-growth data for the
/// Reports & Analytics dashboard. Offline mode pushes the grouping/summing
/// down to SQLite via strftime(); Online (MongoDB) mode replicates the exact
/// same period-bucketing logic in Dart over the fetched collections, since
/// MongoDB has no equivalent of strftime() grouping here.
class ReportsRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  List<DateTime> _lastNMonths(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final monthsAgo = (n - 1) - i;
      return DateTime(now.year, now.month - monthsAgo, 1);
    });
  }

  List<DateTime> _lastNYears(int n) {
    final currentYear = DateTime.now().year;
    return List.generate(n, (i) => DateTime(currentYear - (n - 1) + i, 1, 1));
  }

  String _monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  String _yearKey(DateTime d) => d.year.toString().padLeft(4, '0');

  Future<Map<String, double>> _sumGroupedByMonth(String table, String dateColumn) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT strftime('%Y-%m', $dateColumn) AS period, SUM(amount) AS total
      FROM $table
      GROUP BY period
    ''');
    final map = <String, double>{};
    for (final row in rows) {
      final period = row['period'] as String?;
      if (period != null) {
        map[period] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return map;
  }

  Future<Map<String, double>> _sumGroupedByYear(String table, String dateColumn) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT strftime('%Y', $dateColumn) AS period, SUM(amount) AS total
      FROM $table
      GROUP BY period
    ''');
    final map = <String, double>{};
    for (final row in rows) {
      final period = row['period'] as String?;
      if (period != null) {
        map[period] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return map;
  }

  Map<String, double> _sumGroupedByMonthFromDocs(List<Map<String, dynamic>> docs, String dateColumn) {
    final map = <String, double>{};
    for (final doc in docs) {
      final dateStr = doc[dateColumn] as String?;
      if (dateStr == null || dateStr.length < 7) continue;
      final period = dateStr.substring(0, 7);
      map[period] = (map[period] ?? 0.0) + ((doc['amount'] as num?)?.toDouble() ?? 0.0);
    }
    return map;
  }

  Map<String, double> _sumGroupedByYearFromDocs(List<Map<String, dynamic>> docs, String dateColumn) {
    final map = <String, double>{};
    for (final doc in docs) {
      final dateStr = doc[dateColumn] as String?;
      if (dateStr == null || dateStr.length < 4) continue;
      final period = dateStr.substring(0, 4);
      map[period] = (map[period] ?? 0.0) + ((doc['amount'] as num?)?.toDouble() ?? 0.0);
    }
    return map;
  }

  Future<List<PeriodValue>> getIncomeSeries({required ReportGranularity granularity, int periods = 12}) async {
    Map<String, double> raw;
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('payments');
      raw = granularity == ReportGranularity.monthly
          ? _sumGroupedByMonthFromDocs(docs, 'paymentDate')
          : _sumGroupedByYearFromDocs(docs, 'paymentDate');
    } else {
      raw = granularity == ReportGranularity.monthly
          ? await _sumGroupedByMonth('payments', 'paymentDate')
          : await _sumGroupedByYear('payments', 'paymentDate');
    }
    return _buildSeries(raw, granularity, periods);
  }

  Future<List<PeriodValue>> getExpenseSeries({required ReportGranularity granularity, int periods = 12}) async {
    Map<String, double> raw;
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('expenses');
      raw = granularity == ReportGranularity.monthly
          ? _sumGroupedByMonthFromDocs(docs, 'expenseDate')
          : _sumGroupedByYearFromDocs(docs, 'expenseDate');
    } else {
      raw = granularity == ReportGranularity.monthly
          ? await _sumGroupedByMonth('expenses', 'expenseDate')
          : await _sumGroupedByYear('expenses', 'expenseDate');
    }
    return _buildSeries(raw, granularity, periods);
  }

  List<PeriodValue> _buildSeries(Map<String, double> raw, ReportGranularity granularity, int periods) {
    final buckets = granularity == ReportGranularity.monthly ? _lastNMonths(periods) : _lastNYears(periods);
    return buckets.map((d) {
      final key = granularity == ReportGranularity.monthly ? _monthKey(d) : _yearKey(d);
      return PeriodValue(d, raw[key] ?? 0.0);
    }).toList();
  }

  /// New member sign-ups per period (non-deleted members grouped by createdAt).
  Future<List<PeriodValue>> getNewMemberSeries({required ReportGranularity granularity, int periods = 12}) async {
    final raw = <String, double>{};

    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('members');
      for (final doc in docs) {
        if (doc['deletedAt'] != null) continue;
        final dateStr = doc['createdAt'] as String?;
        final minLen = granularity == ReportGranularity.monthly ? 7 : 4;
        if (dateStr == null || dateStr.length < minLen) continue;
        final period = dateStr.substring(0, minLen);
        raw[period] = (raw[period] ?? 0.0) + 1;
      }
    } else {
      final db = await _db;
      final format = granularity == ReportGranularity.monthly ? '%Y-%m' : '%Y';
      final rows = await db.rawQuery('''
        SELECT strftime('$format', createdAt) AS period, COUNT(*) AS cnt
        FROM members
        WHERE deletedAt IS NULL
        GROUP BY period
      ''');
      for (final row in rows) {
        final period = row['period'] as String?;
        if (period != null) {
          raw[period] = (row['cnt'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return _buildSeries(raw, granularity, periods);
  }

  /// Cumulative total active (non-deleted) member count as of the end of each period,
  /// used for the overall growth trend line.
  Future<List<PeriodValue>> getCumulativeMemberSeries({required ReportGranularity granularity, int periods = 12}) async {
    final newMembers = await getNewMemberSeries(granularity: granularity, periods: periods);
    if (newMembers.isEmpty) return [];

    final firstPeriodStart = newMembers.first.period;
    double running;

    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('members');
      running = docs.where((doc) {
        if (doc['deletedAt'] != null) return false;
        final createdAt = DateTime.tryParse(doc['createdAt'] as String? ?? '');
        return createdAt != null && createdAt.isBefore(firstPeriodStart);
      }).length.toDouble();
    } else {
      final db = await _db;
      final baselineResult = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM members WHERE deletedAt IS NULL AND createdAt < ?',
        [firstPeriodStart.toIso8601String()],
      );
      running = (baselineResult.first['cnt'] as num?)?.toDouble() ?? 0.0;
    }

    return newMembers.map((pv) {
      running += pv.value;
      return PeriodValue(pv.period, running);
    }).toList();
  }

  Map<String, double> _breakdownFromDocs(
    List<Map<String, dynamic>> docs,
    String dateColumn,
    String groupColumn, {
    DateTime? from,
    DateTime? to,
  }) {
    final totals = <String, double>{};
    for (final doc in docs) {
      final dateStr = doc[dateColumn] as String?;
      final date = dateStr == null ? null : DateTime.tryParse(dateStr);
      if (from != null && (date == null || date.isBefore(from))) continue;
      if (to != null && (date == null || !date.isBefore(to))) continue;
      final key = doc[groupColumn] as String?;
      if (key == null) continue;
      totals[key] = (totals[key] ?? 0.0) + ((doc['amount'] as num?)?.toDouble() ?? 0.0);
    }
    final sortedEntries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sortedEntries) e.key: e.value};
  }

  /// Expense totals grouped by category within an optional date range (inclusive start, exclusive end).
  Future<Map<String, double>> getExpenseCategoryBreakdown({DateTime? from, DateTime? to}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('expenses');
      return _breakdownFromDocs(docs, 'expenseDate', 'category', from: from, to: to);
    }

    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('expenseDate >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('expenseDate < ?');
      args.add(to.toIso8601String());
    }
    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
    final rows = await db.rawQuery('''
      SELECT category, SUM(amount) AS total
      FROM expenses
      $whereClause
      GROUP BY category
      ORDER BY total DESC
    ''', args);

    final map = <String, double>{};
    for (final row in rows) {
      final category = row['category'] as String?;
      if (category != null) {
        map[category] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return map;
  }

  /// Income totals grouped by payment method within an optional date range.
  Future<Map<String, double>> getPaymentMethodBreakdown({DateTime? from, DateTime? to}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('payments');
      return _breakdownFromDocs(docs, 'paymentDate', 'paymentMethod', from: from, to: to);
    }

    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('paymentDate >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('paymentDate < ?');
      args.add(to.toIso8601String());
    }
    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
    final rows = await db.rawQuery('''
      SELECT paymentMethod, SUM(amount) AS total
      FROM payments
      $whereClause
      GROUP BY paymentMethod
      ORDER BY total DESC
    ''', args);

    final map = <String, double>{};
    for (final row in rows) {
      final method = row['paymentMethod'] as String?;
      if (method != null) {
        map[method] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return map;
  }
}
