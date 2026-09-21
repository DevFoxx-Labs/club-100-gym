class EventModel {
  final String id;
  final String title;
  final String? description;
  final String startTime;
  final String endTime;
  final String? location;
  final String? trainerId;
  final int? colorValue;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.trainerId,
    this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'trainerId': trainerId,
      'colorValue': colorValue,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      location: map['location'] as String?,
      trainerId: map['trainerId'] as String?,
      colorValue: map['colorValue'] as int?,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      deletedAt: map['deletedAt'] as String?,
    );
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? startTime,
    String? endTime,
    String? location,
    String? trainerId,
    int? colorValue,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      trainerId: trainerId ?? this.trainerId,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

