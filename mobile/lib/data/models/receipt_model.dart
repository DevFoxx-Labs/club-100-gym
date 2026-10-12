class ReceiptModel {
  final String id;
  final String paymentId;
  final String receiptNumber; // e.g. GYM-2026-00001
  final String? billNumber; // e.g. BILL-2026-00001, when tied to a generated bill
  final String memberName;
  final String memberPhone;
  final String planName;
  final String? trainerName;
  final double personalTrainingFee;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final DateTime startDate;
  final DateTime endDate;
  final String qrPayload;
  final DateTime createdAt;

  /// Snapshot of the linked bill at the moment this receipt was issued: the
  /// bill's full amount and what was still owed AFTER this payment. Null for
  /// receipts not tied to a bill (and for receipts issued before this field
  /// existed). Snapshotted so reprinting an old installment receipt later
  /// still shows the balance as it was on that day.
  final double? billTotal;
  final double? balanceDue;

  ReceiptModel({
    required this.id,
    required this.paymentId,
    required this.receiptNumber,
    this.billNumber,
    required this.memberName,
    required this.memberPhone,
    required this.planName,
    this.trainerName,
    this.personalTrainingFee = 0.0,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.startDate,
    required this.endDate,
    required this.qrPayload,
    required this.createdAt,
    this.billTotal,
    this.balanceDue,
  });

  /// True when this payment covered only part of its bill (an installment).
  bool get isInstallment => billTotal != null && amount < billTotal! - 0.01;

  bool get leavesBalance => (balanceDue ?? 0) > 0.009;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'receiptNumber': receiptNumber,
      'billNumber': billNumber,
      'memberName': memberName,
      'memberPhone': memberPhone,
      'planName': planName,
      'trainerName': trainerName,
      'personalTrainingFee': personalTrainingFee,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'qrPayload': qrPayload,
      'createdAt': createdAt.toIso8601String(),
      'billTotal': billTotal,
      'balanceDue': balanceDue,
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] ?? '',
      paymentId: map['paymentId'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
      billNumber: map['billNumber'],
      memberName: map['memberName'] ?? '',
      memberPhone: map['memberPhone'] ?? '',
      planName: map['planName'] ?? '',
      trainerName: map['trainerName'],
      personalTrainingFee: (map['personalTrainingFee'] ?? 0.0).toDouble(),
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      paymentDate: DateTime.parse(map['paymentDate']),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      qrPayload: map['qrPayload'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      billTotal: (map['billTotal'] as num?)?.toDouble(),
      balanceDue: (map['balanceDue'] as num?)?.toDouble(),
    );
  }

  ReceiptModel copyWith({
    String? id,
    String? paymentId,
    String? receiptNumber,
    String? billNumber,
    String? memberName,
    String? memberPhone,
    String? planName,
    String? trainerName,
    double? personalTrainingFee,
    double? amount,
    String? paymentMethod,
    DateTime? paymentDate,
    DateTime? startDate,
    DateTime? endDate,
    String? qrPayload,
    DateTime? createdAt,
    double? billTotal,
    double? balanceDue,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      billNumber: billNumber ?? this.billNumber,
      memberName: memberName ?? this.memberName,
      memberPhone: memberPhone ?? this.memberPhone,
      planName: planName ?? this.planName,
      trainerName: trainerName ?? this.trainerName,
      personalTrainingFee: personalTrainingFee ?? this.personalTrainingFee,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      qrPayload: qrPayload ?? this.qrPayload,
      createdAt: createdAt ?? this.createdAt,
      billTotal: billTotal ?? this.billTotal,
      balanceDue: balanceDue ?? this.balanceDue,
    );
  }
}
