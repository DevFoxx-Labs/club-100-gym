class AnnouncementModel {
  final String id;
  final String message;
  final String? imagePath;
  final String audienceType; // 'all', 'active', 'overdue', 'expiring', 'plan'
  final String audienceLabel;
  final String? audiencePlanId;
  final bool isImportant;
  final bool isPinned;
  final String status; // 'sent', 'scheduled'
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.message,
    this.imagePath,
    this.audienceType = 'all',
    this.audienceLabel = 'All Members',
    this.audiencePlanId,
    this.isImportant = false,
    this.isPinned = false,
    this.status = 'sent',
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
  });

  bool get isScheduled => status == 'scheduled';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'imagePath': imagePath,
      'audienceType': audienceType,
      'audienceLabel': audienceLabel,
      'audiencePlanId': audiencePlanId,
      'isImportant': isImportant ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'status': status,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id'] ?? '',
      message: map['message'] ?? '',
      imagePath: map['imagePath'],
      audienceType: map['audienceType'] ?? 'all',
      audienceLabel: map['audienceLabel'] ?? 'All Members',
      audiencePlanId: map['audiencePlanId'],
      isImportant: (map['isImportant'] ?? 0) == 1,
      isPinned: (map['isPinned'] ?? 0) == 1,
      status: map['status'] ?? 'sent',
      scheduledAt: map['scheduledAt'] != null ? DateTime.parse(map['scheduledAt']) : null,
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  AnnouncementModel copyWith({
    String? message,
    String? imagePath,
    bool clearImage = false,
    String? audienceType,
    String? audienceLabel,
    String? audiencePlanId,
    bool? isImportant,
    bool? isPinned,
    String? status,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    DateTime? sentAt,
  }) {
    return AnnouncementModel(
      id: id,
      message: message ?? this.message,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      audienceType: audienceType ?? this.audienceType,
      audienceLabel: audienceLabel ?? this.audienceLabel,
      audiencePlanId: audiencePlanId ?? this.audiencePlanId,
      isImportant: isImportant ?? this.isImportant,
      isPinned: isPinned ?? this.isPinned,
      status: status ?? this.status,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt,
    );
  }
}
