import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'db_tables.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('club_100_gym.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(DbTables.gym);
    await db.execute(DbTables.admins);
    await db.execute(DbTables.membershipPlans);
    await db.execute(DbTables.members);
    await db.execute(DbTables.memberships);
    await db.execute(DbTables.payments);
    await db.execute(DbTables.receipts);
    await db.execute(DbTables.notifications);
    await db.execute(DbTables.notificationSettings);
    await db.execute(DbTables.appSettings);

    // Seed default plans
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();
    
    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'name': 'Monthly Plan',
      'durationDays': 30,
      'defaultFee': 1500.0,
      'description': 'Full access to gym equipment and cardio zone for 1 Month',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'name': 'Quarterly Pro Plan',
      'durationDays': 90,
      'defaultFee': 3999.0,
      'description': 'Pro All Access: HIIT, Aerobics & Crossfit for 3 Months',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'name': 'Half-Yearly VIP Plan',
      'durationDays': 180,
      'defaultFee': 7499.0,
      'description': '6 Months Unlimited Gym Access + Free Trainer Assessment',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'name': 'Yearly Elite Plan',
      'durationDays': 365,
      'defaultFee': 12999.0,
      'description': '1 Year All Access + Nutrition Coaching + Personal Session',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    // Seed default notification settings
    await db.insert('notification_settings', {
      'id': 'default',
      'feeReminder7Days': 1,
      'feeReminder3Days': 1,
      'feeReminder1Day': 1,
      'feeReminderDueToday': 1,
      'feeReminderOverdue': 1,
      'membershipReminder7Days': 1,
      'membershipReminder3Days': 1,
      'membershipReminder1Day': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Database schema migrations for future version upgrades
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('gym');
    await db.delete('admins');
    await db.delete('members');
    await db.delete('memberships');
    await db.delete('payments');
    await db.delete('receipts');
    await db.delete('notifications');
    await db.delete('app_settings');
  }
}

