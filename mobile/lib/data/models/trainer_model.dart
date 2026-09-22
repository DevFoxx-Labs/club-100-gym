class TrainerModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String? specialization;
  final double? monthlySalary;
  final String? photoPath;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  TrainerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.role = 'Trainer',
    this.specialization,
    this.monthlySalary,
    this.photoPath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get speciality => (specialization != null && specialization!.isNotEmpty) ? specialization! : 'General';

  /// Splits the comma-separated specialization field into individual tag labels.
  List<String> get specializationTags => (specialization == null || specialization!.trim().isEmpty)
      ? []
      : specialization!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'specialization': specialization,
      'monthlySalary': monthlySalary,
      'photoPath': photoPath,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  factory TrainerModel.fromMap(Map<String, dynamic> map) {
    return TrainerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      role: (map['role'] as String?) ?? 'Trainer',
      specialization: map['specialization'] as String?,
      monthlySalary: (map['monthlySalary'] as num?)?.toDouble(),
      photoPath: map['photoPath'] as String?,
      isActive: (map['isActive'] as int?) == 1,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      deletedAt: map['deletedAt'] as String?,
    );
  }

  TrainerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? specialization,
    double? monthlySalary,
    String? photoPath,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return TrainerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
