class MembershipModel {
  final String id;
  final String memberId;
  final String planId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final double feeAmount;
  final String status; // Active, Expiring Soon, Expired, Inactive
  final DateTime createdAt;
  final DateTime updatedAt;

  MembershipModel({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.planName,
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
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      feeAmount: (map['feeAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}

