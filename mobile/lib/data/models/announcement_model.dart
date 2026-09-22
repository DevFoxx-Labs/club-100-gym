class AnnouncementModel {
  final String id;
  final String? title;
  final String message;
  final String? imagePath;
  final String category; // 'class', 'equipment', 'hours', 'event', 'maintenance', 'general'
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
    this.title,
    required this.message,
    this.imagePath,
    this.category = 'general',
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

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    final firstLine = message.split('\n').first.trim();
    return firstLine.isNotEmpty ? firstLine : 'Announcement';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'imagePath': imagePath,
      'category': category,
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
      title: map['title'],
      message: map['message'] ?? '',
      imagePath: map['imagePath'],
      category: map['category'] ?? 'general',
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
    String? title,
    String? message,
    String? imagePath,
    bool clearImage = false,
    String? category,
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
      title: title ?? this.title,
      message: message ?? this.message,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      category: category ?? this.category,
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
