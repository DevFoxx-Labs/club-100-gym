class TrainerChangeLogModel {
  final String id;
  final String memberId;
  final String? membershipId;
  final String? previousTrainerId;
  final String? previousTrainerNameSnapshot;
  final String? newTrainerId;
  final String? newTrainerNameSnapshot;
  final double previousPersonalTrainingFee;
  final double newPersonalTrainingFee;
  final String? reason;
  final String changedAt;

  TrainerChangeLogModel({
    required this.id,
    required this.memberId,
    this.membershipId,
    this.previousTrainerId,
    this.previousTrainerNameSnapshot,
    this.newTrainerId,
    this.newTrainerNameSnapshot,
    this.previousPersonalTrainingFee = 0.0,
    this.newPersonalTrainingFee = 0.0,
    this.reason,
    required this.changedAt,
  });

  String? get previousTrainerName => previousTrainerNameSnapshot;
  String? get newTrainerName => newTrainerNameSnapshot;
  DateTime get changedAtDate => DateTime.tryParse(changedAt) ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'membershipId': membershipId,
      'previousTrainerId': previousTrainerId,
      'previousTrainerNameSnapshot': previousTrainerNameSnapshot,
      'newTrainerId': newTrainerId,
      'newTrainerNameSnapshot': newTrainerNameSnapshot,
      'previousPersonalTrainingFee': previousPersonalTrainingFee,
      'newPersonalTrainingFee': newPersonalTrainingFee,
      'reason': reason,
      'changedAt': changedAt,
    };
  }

  factory TrainerChangeLogModel.fromMap(Map<String, dynamic> map) {
    return TrainerChangeLogModel(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      membershipId: map['membershipId'] as String?,
      previousTrainerId: map['previousTrainerId'] as String?,
      previousTrainerNameSnapshot: map['previousTrainerNameSnapshot'] as String?,
      newTrainerId: map['newTrainerId'] as String?,
      newTrainerNameSnapshot: map['newTrainerNameSnapshot'] as String?,
      previousPersonalTrainingFee: (map['previousPersonalTrainingFee'] as num?)?.toDouble() ?? 0.0,
      newPersonalTrainingFee: (map['newPersonalTrainingFee'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String?,
      changedAt: map['changedAt'] as String,
    );
  }
}

