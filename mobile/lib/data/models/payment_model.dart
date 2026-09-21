class PaymentModel {
  final String id;
  final String memberId;
  final String? membershipId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // Cash, UPI, Card, Bank Transfer, Other
  final String? notes;
  final String receiptId;
  final String receiptNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? memberName;
  final String? planName;

  PaymentModel({
    required this.id,
    required this.memberId,
    this.membershipId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    required this.receiptId,
    required this.receiptNumber,
    required this.createdAt,
    required this.updatedAt,
    this.memberName,
    this.planName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'membershipId': membershipId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'receiptId': receiptId,
      'receiptNumber': receiptNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      memberId: map['memberId'] ?? '',
      membershipId: map['membershipId'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate']),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      notes: map['notes'],
      receiptId: map['receiptId'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      memberName: map['memberName'] ?? map['member_name'],
      planName: map['planName'] ?? map['plan_name'],
    );
  }

  PaymentModel copyWith({
    String? id,
    String? memberId,
    String? membershipId,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    String? receiptId,
    String? receiptNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? memberName,
    String? planName,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      membershipId: membershipId ?? this.membershipId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      receiptId: receiptId ?? this.receiptId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberName: memberName ?? this.memberName,
      planName: planName ?? this.planName,
    );
  }
}

