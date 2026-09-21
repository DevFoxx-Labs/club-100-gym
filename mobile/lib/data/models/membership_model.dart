class MembershipModel {
  final String id;
  final String memberId;
  final String planId;
  final String planName;
  final String? trainerId;
  final double personalTrainingFee;
  final String? packageId;
  final DateTime startDate;
  final DateTime endDate;
  final double feeAmount;
  final String status; // Active, Expiring Soon, Expired, Inactive, Superseded
  final DateTime createdAt;
  final DateTime updatedAt;

  MembershipModel({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.planName,
    this.trainerId,
    this.personalTrainingFee = 0.0,
    this.packageId,
    required this.startDate,
    required this.endDate,
    required this.feeAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'planId': planId,
      'planName': planName,
      'trainerId': trainerId,
      'personalTrainingFee': personalTrainingFee,
      'packageId': packageId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'feeAmount': feeAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MembershipModel.fromMap(Map<String, dynamic> map) {
    return MembershipModel(
      id: map['id'] ?? '',
      memberId: map['memberId'] ?? '',
      planId: map['planId'] ?? '',
      planName: map['planName'] ?? 'Standard Plan',
      trainerId: map['trainerId'],
      personalTrainingFee: (map['personalTrainingFee'] as num?)?.toDouble() ?? 0.0,
      packageId: map['packageId'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      feeAmount: (map['feeAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  MembershipModel copyWith({
    String? id,
    String? memberId,
    String? planId,
    String? planName,
    String? trainerId,
    double? personalTrainingFee,
    String? packageId,
    DateTime? startDate,
    DateTime? endDate,
    double? feeAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipModel(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      trainerId: trainerId ?? this.trainerId,
      personalTrainingFee: personalTrainingFee ?? this.personalTrainingFee,
      packageId: packageId ?? this.packageId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      feeAmount: feeAmount ?? this.feeAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

