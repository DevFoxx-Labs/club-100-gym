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
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Ensure trainers table has photoPath
    try {
      await db.execute('ALTER TABLE trainers ADD COLUMN photoPath TEXT;');
    } catch (_) {}

    // Ensure gym table has website
    try {
      await db.execute('ALTER TABLE gym ADD COLUMN website TEXT;');
    } catch (_) {}

    // Ensure receipts table has trainerName and personalTrainingFee
    try {
      await db.execute('ALTER TABLE receipts ADD COLUMN trainerName TEXT;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE receipts ADD COLUMN personalTrainingFee REAL DEFAULT 0.0;');
    } catch (_) {}

    // Self-heal any memberships where feeAmount was corrupted to <= personalTrainingFee
    try {
      await db.execute('''
        UPDATE memberships
        SET feeAmount = (SELECT defaultFee FROM membership_plans WHERE membership_plans.id = memberships.planId) + personalTrainingFee
        WHERE personalTrainingFee > 0 AND feeAmount <= personalTrainingFee AND EXISTS (SELECT 1 FROM membership_plans WHERE membership_plans.id = memberships.planId);
      ''');
    } catch (_) {}

    // Ensure dismissed_notifications table exists for tracking dismissed alerts today
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dismissed_notifications (
          dismissKey TEXT PRIMARY KEY,
          dismissedDate TEXT NOT NULL
        );
      ''');
    } catch (_) {}

    // Ensure announcements table exists for the Announcements broadcast feature
    try {
      await db.execute(DbTables.announcements);
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE announcements ADD COLUMN title TEXT;');
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE announcements ADD COLUMN category TEXT DEFAULT 'general';");
    } catch (_) {}

    // Ensure expenses table exists for the Expense Tracker feature
    try {
      await db.execute(DbTables.expenses);
    } catch (_) {}

    // Ensure gym table has UPI/Bank payment collection columns
    for (final stmt in [
      'ALTER TABLE gym ADD COLUMN upiId TEXT;',
      'ALTER TABLE gym ADD COLUMN upiPayeeName TEXT;',
      'ALTER TABLE gym ADD COLUMN bankAccountHolder TEXT;',
      'ALTER TABLE gym ADD COLUMN bankAccountNumber TEXT;',
      'ALTER TABLE gym ADD COLUMN bankIfsc TEXT;',
      'ALTER TABLE gym ADD COLUMN bankName TEXT;',
      'ALTER TABLE gym ADD COLUMN showUpiQrOnBill INTEGER DEFAULT 1;',
      'ALTER TABLE gym ADD COLUMN showBankDetailsOnBill INTEGER DEFAULT 1;',
    ]) {
      try {
        await db.execute(stmt);
      } catch (_) {}
    }

    // Ensure bills table exists for the Billing & Dues Tracking feature
    try {
      await db.execute(DbTables.bills);
    } catch (_) {}

    // Ensure gym table has defaultPrintFormat for remembering the preferred paper size
    try {
      await db.execute('ALTER TABLE gym ADD COLUMN defaultPrintFormat TEXT;');
    } catch (_) {}

    // Ensure receipts table has billNumber for receipts tied to a generated bill
    try {
      await db.execute('ALTER TABLE receipts ADD COLUMN billNumber TEXT;');
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
    await db.execute(DbTables.announcements);
    await db.execute(DbTables.expenses);
    await db.execute(DbTables.bills);

    // Seed default packages and plans
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();
    final defaultPackageId = uuid.v4();

    // cardio + crossfit package
    await db.insert('membership_packages', {
      'id': defaultPackageId,
      'name': 'Cardio + Crossfit',
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
      'defaultFee': 2000.0,
      'description': 'Full access to gym equipment and cardio zone for 1 Month',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultPackageId,
      'name': 'Quarterly Plan',
      'durationDays': 90,
      'defaultFee': 4500.0,
      'description': 'Premium All Access: HIIT, Aerobics & Crossfit for 3 Months',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultPackageId,
      'name': 'Half-Yearly Plan',
      'durationDays': 180,
      'defaultFee': 7500.0,
      'description': '6 Months Unlimited Gym Access',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultPackageId,
      'name': 'Annual/Yearly Elite Plan',
      'durationDays': 365,
      'defaultFee': 12000.0,
      'description': '1 Year All Access',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    // strength training package
    final defaultStrengthTrainingPackageId = uuid.v4();
    await db.insert('membership_packages', {
      'id': defaultStrengthTrainingPackageId,
      'name': 'Strength Training',
      'description': 'Full access to gym equipment, free weights, and cardio zone',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });
    
    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultStrengthTrainingPackageId,
      'name': 'Monthly Plan',
      'durationDays': 30,
      'defaultFee': 1800.0,
      'description': 'Full access to gym equipment and cardio zone for 1 Month',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultStrengthTrainingPackageId,
      'name': 'Quarterly Plan',
      'durationDays': 90,
      'defaultFee': 4200.0,
      'description': 'Premium All Access: HIIT, Aerobics & Crossfit for 3 Months',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultStrengthTrainingPackageId,
      'name': 'Half-Yearly Plan',
      'durationDays': 180,
      'defaultFee': 7000.0,
      'description': '6 Months Unlimited Gym Access',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultStrengthTrainingPackageId,
      'name': 'Annual/Yearly Elite Plan',
      'durationDays': 365,
      'defaultFee': 11000.0,
      'description': '1 Year All Access',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    // strength training package
    final defaultTotalFitnessPackageId = uuid.v4();
    await db.insert('membership_packages', {
      'id': defaultTotalFitnessPackageId,
      'name': 'Total Fitness',
      'description': 'Full access to gym equipment, free weights, and cardio zone',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });
    
    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultTotalFitnessPackageId,
      'name': 'Monthly Plan',
      'durationDays': 30,
      'defaultFee': 2500.0,
      'description': 'Full access to gym equipment and cardio zone for 1 Month',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultTotalFitnessPackageId,
      'name': 'Quarterly Plan',
      'durationDays': 90,
      'defaultFee': 6000.0,
      'description': 'Premium All Access: HIIT, Aerobics & Crossfit for 3 Months',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultTotalFitnessPackageId,
      'name': 'Half-Yearly Plan',
      'durationDays': 180,
      'defaultFee': 10000.0,
      'description': '6 Months Unlimited Gym Access',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('membership_plans', {
      'id': uuid.v4(),
      'packageId': defaultTotalFitnessPackageId,
      'name': 'Annual/Yearly Elite Plan',
      'durationDays': 365,
      'defaultFee': 15000.0,
      'description': '1 Year All Access',
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

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE gym ADD COLUMN website TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE receipts ADD COLUMN trainerName TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE receipts ADD COLUMN personalTrainingFee REAL DEFAULT 0.0;');
      } catch (_) {}
    }

    if (oldVersion < 5) {
      try {
        await db.execute(DbTables.announcements);
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await db.execute(DbTables.expenses);
      } catch (_) {}
    }

    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE trainers ADD COLUMN role TEXT DEFAULT 'Trainer';");
      } catch (_) {}
    }

    if (oldVersion < 8) {
      for (final stmt in [
        'ALTER TABLE gym ADD COLUMN upiId TEXT;',
        'ALTER TABLE gym ADD COLUMN upiPayeeName TEXT;',
        'ALTER TABLE gym ADD COLUMN bankAccountHolder TEXT;',
        'ALTER TABLE gym ADD COLUMN bankAccountNumber TEXT;',
        'ALTER TABLE gym ADD COLUMN bankIfsc TEXT;',
        'ALTER TABLE gym ADD COLUMN bankName TEXT;',
        'ALTER TABLE gym ADD COLUMN showUpiQrOnBill INTEGER DEFAULT 1;',
        'ALTER TABLE gym ADD COLUMN showBankDetailsOnBill INTEGER DEFAULT 1;',
      ]) {
        try {
          await db.execute(stmt);
        } catch (_) {}
      }
      try {
        await db.execute(DbTables.bills);
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
    await db.delete('announcements');
    await db.delete('expenses');
    await db.delete('bills');
    await db.delete('app_settings');
  }
}

