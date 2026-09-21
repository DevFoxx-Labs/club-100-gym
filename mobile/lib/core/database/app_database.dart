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

    final db = await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Ensure trainers table has photoPath
    try {
      await db.execute('ALTER TABLE trainers ADD COLUMN photoPath TEXT;');
    } catch (_) {}

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(DbTables.gym);
    await db.execute(DbTables.admins);
    await db.execute(DbTables.membershipPackages);
    await db.execute(DbTables.membershipPlans);
    await db.execute(DbTables.trainers);
    await db.execute(DbTables.trainerPayouts);
    await db.execute(DbTables.trainerChangeLogs);
    await db.execute(DbTables.events);
    await db.execute(DbTables.members);
    await db.execute(DbTables.memberships);
    await db.execute(DbTables.membershipChangeLogs);
    await db.execute(DbTables.payments);
    await db.execute(DbTables.receipts);
    await db.execute(DbTables.notifications);
    await db.execute(DbTables.notificationSettings);
    await db.execute(DbTables.appSettings);

    // Seed default packages and plans
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();
    final defaultPackageId = uuid.v4();

    await db.insert('membership_packages', {
      'id': defaultPackageId,
      'name': 'Standard Gym Access',
      'description': 'Full access to gym equipment, free weights, and cardio zone',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });
    
    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultPackageId,
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
      'packageId': defaultPackageId,
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
      'packageId': defaultPackageId,
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
      'packageId': defaultPackageId,
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
    if (oldVersion < 2) {
      await db.execute(DbTables.membershipPackages);
      await db.execute(DbTables.trainers);
      await db.execute(DbTables.trainerPayouts);
      await db.execute(DbTables.trainerChangeLogs);
      await db.execute(DbTables.events);
      await db.execute(DbTables.membershipChangeLogs);

      try { await db.execute('ALTER TABLE memberships ADD COLUMN trainerId TEXT;'); } catch (_) {}
      try { await db.execute('ALTER TABLE memberships ADD COLUMN personalTrainingFee REAL DEFAULT 0;'); } catch (_) {}
      try { await db.execute('ALTER TABLE memberships ADD COLUMN packageId TEXT;'); } catch (_) {}
      try { await db.execute('ALTER TABLE membership_plans ADD COLUMN packageId TEXT;'); } catch (_) {}
      try { await db.execute('ALTER TABLE members ADD COLUMN email TEXT;'); } catch (_) {}

      // Seed default package if none exists
      final packages = await db.query('membership_packages');
      if (packages.isEmpty) {
        const uuid = Uuid();
        final now = DateTime.now().toIso8601String();
        final defaultPackageId = uuid.v4();
        await db.insert('membership_packages', {
          'id': defaultPackageId,
          'name': 'Standard Gym Access',
          'description': 'Full access to gym equipment, free weights, and cardio zone',
          'isActive': 1,
          'createdAt': now,
          'updatedAt': now,
        });
        await db.update(
          'membership_plans',
          {'packageId': defaultPackageId},
          where: 'packageId IS NULL',
        );
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE trainers ADD COLUMN photoPath TEXT;');
      } catch (_) {}
    }
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
    await db.delete('membership_packages');
    await db.delete('membership_plans');
    await db.delete('trainers');
    await db.delete('trainer_payouts');
    await db.delete('trainer_change_logs');
    await db.delete('events');
    await db.delete('members');
    await db.delete('memberships');
    await db.delete('membership_change_logs');
    await db.delete('payments');
    await db.delete('receipts');
    await db.delete('notifications');
    await db.delete('app_settings');
  }
}

