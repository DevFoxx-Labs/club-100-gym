class DbTables {
  static const String gym = '''
    CREATE TABLE IF NOT EXISTS gym (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      ownerName TEXT,
      phone TEXT NOT NULL,
      email TEXT,
      website TEXT,
      address TEXT NOT NULL,
      city TEXT,
      logoPath TEXT,
      currency TEXT DEFAULT 'INR (₹)',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String admins = '''
    CREATE TABLE IF NOT EXISTS admins (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT,
      isBiometricEnabled INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String membershipPlans = '''
    CREATE TABLE IF NOT EXISTS membership_plans (
      id TEXT PRIMARY KEY,
      packageId TEXT,
      name TEXT NOT NULL,
      durationDays INTEGER NOT NULL,
      defaultFee REAL NOT NULL,
      description TEXT,
      isActive INTEGER DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String members = '''
    CREATE TABLE IF NOT EXISTS members (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT,
      gender TEXT,
      dateOfBirth TEXT,
      photoPath TEXT,
      notes TEXT,
      isArchived INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deletedAt TEXT
    );
  ''';

  static const String memberships = '''
    CREATE TABLE IF NOT EXISTS memberships (
      id TEXT PRIMARY KEY,
      memberId TEXT NOT NULL,
      planId TEXT NOT NULL,
      planName TEXT NOT NULL,
      trainerId TEXT,
      personalTrainingFee REAL DEFAULT 0,
      packageId TEXT,
      startDate TEXT NOT NULL,
      endDate TEXT NOT NULL,
      feeAmount REAL NOT NULL,
      status TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
    );
  ''';

  static const String payments = '''
    CREATE TABLE IF NOT EXISTS payments (
      id TEXT PRIMARY KEY,
      memberId TEXT NOT NULL,
      membershipId TEXT,
      amount REAL NOT NULL,
      paymentDate TEXT NOT NULL,
      paymentMethod TEXT NOT NULL,
      notes TEXT,
      receiptId TEXT NOT NULL,
      receiptNumber TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
    );
  ''';

  static const String receipts = '''
    CREATE TABLE IF NOT EXISTS receipts (
      id TEXT PRIMARY KEY,
      paymentId TEXT NOT NULL,
      receiptNumber TEXT NOT NULL UNIQUE,
      memberName TEXT NOT NULL,
      memberPhone TEXT NOT NULL,
      planName TEXT NOT NULL,
      trainerName TEXT,
      personalTrainingFee REAL DEFAULT 0.0,
      amount REAL NOT NULL,
      paymentMethod TEXT NOT NULL,
      paymentDate TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT NOT NULL,
      qrPayload TEXT NOT NULL,
      createdAt TEXT NOT NULL
    );
  ''';

  static const String notifications = '''
    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      memberId TEXT,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      scheduledAt TEXT NOT NULL,
      triggeredAt TEXT,
      isRead INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    );
  ''';

  static const String announcements = '''
    CREATE TABLE IF NOT EXISTS announcements (
      id TEXT PRIMARY KEY,
      message TEXT NOT NULL,
      imagePath TEXT,
      audienceType TEXT NOT NULL DEFAULT 'all',
      audienceLabel TEXT NOT NULL DEFAULT 'All Members',
      audiencePlanId TEXT,
      isImportant INTEGER DEFAULT 0,
      isPinned INTEGER DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'sent',
      scheduledAt TEXT,
      sentAt TEXT,
      createdAt TEXT NOT NULL
    );
  ''';

  static const String notificationSettings = '''
    CREATE TABLE IF NOT EXISTS notification_settings (
      id TEXT PRIMARY KEY,
      feeReminder7Days INTEGER DEFAULT 1,
      feeReminder3Days INTEGER DEFAULT 1,
      feeReminder1Day INTEGER DEFAULT 1,
      feeReminderDueToday INTEGER DEFAULT 1,
      feeReminderOverdue INTEGER DEFAULT 1,
      membershipReminder7Days INTEGER DEFAULT 1,
      membershipReminder3Days INTEGER DEFAULT 1,
      membershipReminder1Day INTEGER DEFAULT 1
    );
  ''';

  static const String appSettings = '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  static const String membershipPackages = '''
    CREATE TABLE IF NOT EXISTS membership_packages (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      isActive INTEGER DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deletedAt TEXT
    );
  ''';

  static const String trainers = '''
    CREATE TABLE IF NOT EXISTS trainers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      role TEXT DEFAULT 'Trainer',
      specialization TEXT,
      monthlySalary REAL,
      photoPath TEXT,
      isActive INTEGER DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deletedAt TEXT
    );
  ''';

  static const String trainerPayouts = '''
    CREATE TABLE IF NOT EXISTS trainer_payouts (
      id TEXT PRIMARY KEY,
      trainerId TEXT NOT NULL,
      amount REAL NOT NULL,
      payoutDate TEXT NOT NULL,
      payoutType TEXT DEFAULT 'salary',
      notes TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deletedAt TEXT,
      FOREIGN KEY (trainerId) REFERENCES trainers (id) ON DELETE CASCADE
    );
  ''';

  static const String trainerChangeLogs = '''
    CREATE TABLE IF NOT EXISTS trainer_change_logs (
      id TEXT PRIMARY KEY,
      memberId TEXT NOT NULL,
      membershipId TEXT,
      previousTrainerId TEXT,
      previousTrainerNameSnapshot TEXT,
      newTrainerId TEXT,
      newTrainerNameSnapshot TEXT,
      previousPersonalTrainingFee REAL DEFAULT 0,
      newPersonalTrainingFee REAL DEFAULT 0,
      reason TEXT,
      changedAt TEXT NOT NULL,
      FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
    );
  ''';

  static const String events = '''
    CREATE TABLE IF NOT EXISTS events (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      startTime TEXT NOT NULL,
      endTime TEXT NOT NULL,
      location TEXT,
      trainerId TEXT,
      colorValue INTEGER,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deletedAt TEXT,
      FOREIGN KEY (trainerId) REFERENCES trainers (id) ON DELETE SET NULL
    );
  ''';

  static const String expenses = '''
    CREATE TABLE IF NOT EXISTS expenses (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'Other',
      amount REAL NOT NULL,
      expenseDate TEXT NOT NULL,
      paymentMethod TEXT NOT NULL DEFAULT 'Cash',
      notes TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String membershipChangeLogs = '''
    CREATE TABLE IF NOT EXISTS membership_change_logs (
      id TEXT PRIMARY KEY,
      memberId TEXT NOT NULL,
      previousMembershipId TEXT,
      newMembershipId TEXT NOT NULL,
      previousPlanNameSnapshot TEXT,
      newPlanNameSnapshot TEXT NOT NULL,
      previousFeeAmount REAL,
      newFeeAmount REAL NOT NULL,
      reason TEXT,
      changedAt TEXT NOT NULL,
      FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
    );
  ''';
}

