class MembershipChangeLogModel {
  final String id;
  final String memberId;
  final String? previousMembershipId;
  final String newMembershipId;
  final String? previousPlanNameSnapshot;
  final String newPlanNameSnapshot;
  final double? previousFeeAmount;
  final double newFeeAmount;
  final String? reason;
  final String changedAt;

  MembershipChangeLogModel({
    required this.id,
    required this.memberId,
    this.previousMembershipId,
    required this.newMembershipId,
    this.previousPlanNameSnapshot,
    required this.newPlanNameSnapshot,
    this.previousFeeAmount,
    required this.newFeeAmount,
    this.reason,
    required this.changedAt,
  });

  String get previousPlanName => previousPlanNameSnapshot ?? 'None';
  String get newPlanName => newPlanNameSnapshot;
  DateTime get effectiveDate => DateTime.tryParse(changedAt) ?? DateTime.now();
  double get newFee => newFeeAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'previousMembershipId': previousMembershipId,
      'newMembershipId': newMembershipId,
      'previousPlanNameSnapshot': previousPlanNameSnapshot,
      'newPlanNameSnapshot': newPlanNameSnapshot,
      'previousFeeAmount': previousFeeAmount,
      'newFeeAmount': newFeeAmount,
      'reason': reason,
      'changedAt': changedAt,
    };
  }

  factory MembershipChangeLogModel.fromMap(Map<String, dynamic> map) {
    return MembershipChangeLogModel(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      previousMembershipId: map['previousMembershipId'] as String?,
      newMembershipId: map['newMembershipId'] as String,
      previousPlanNameSnapshot: map['previousPlanNameSnapshot'] as String?,
      newPlanNameSnapshot: map['newPlanNameSnapshot'] as String,
      previousFeeAmount: (map['previousFeeAmount'] as num?)?.toDouble(),
      newFeeAmount: (map['newFeeAmount'] as num).toDouble(),
      reason: map['reason'] as String?,
      changedAt: map['changedAt'] as String,
    );
  }
}

