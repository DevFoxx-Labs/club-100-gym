class TrainerPayoutModel {
  final String id;
  final String trainerId;
  final double amount;
  final String payoutDate;
  final String payoutType; // 'salary', 'personal_training', 'bonus'
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  TrainerPayoutModel({
    required this.id,
    required this.trainerId,
    required this.amount,
    required this.payoutDate,
    this.payoutType = 'salary',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trainerId': trainerId,
      'amount': amount,
      'payoutDate': payoutDate,
      'payoutType': payoutType,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  factory TrainerPayoutModel.fromMap(Map<String, dynamic> map) {
    return TrainerPayoutModel(
      id: map['id'] as String,
      trainerId: map['trainerId'] as String,
      amount: (map['amount'] as num).toDouble(),
      payoutDate: map['payoutDate'] as String,
      payoutType: map['payoutType'] as String? ?? 'salary',
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      deletedAt: map['deletedAt'] as String?,
    );
  }

  String get payoutTypeLabel {
    switch (payoutType) {
      case 'personal_training':
        return 'Personal Training';
      case 'bonus':
        return 'Bonus';
      case 'salary':
      default:
        return 'Salary';
    }
  }
}

