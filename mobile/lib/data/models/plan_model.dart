class PlanModel {
  final String id;
  final String name;
  final int durationDays;
  final double defaultFee;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanModel({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.defaultFee,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'durationDays': durationDays,
      'defaultFee': defaultFee,
      'description': description,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      durationDays: map['durationDays'] ?? 30,
      defaultFee: (map['defaultFee'] ?? 0.0).toDouble(),
      description: map['description'],
      isActive: (map['isActive'] ?? 1) == 1,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}

