class ReceiptModel {
  final String id;
  final String paymentId;
  final String receiptNumber; // e.g. GYM-2026-00001
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

  ReceiptModel({
    required this.id,
    required this.paymentId,
    required this.receiptNumber,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'receiptNumber': receiptNumber,
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
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] ?? '',
      paymentId: map['paymentId'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
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
    );
  }

  ReceiptModel copyWith({
    String? id,
    String? paymentId,
    String? receiptNumber,
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
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
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
    );
  }
}
