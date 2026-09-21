enum NotificationType {
  feeDueSoon,
  feeDueToday,
  feeOverdue,
  membershipExpiring,
  custom,
}

class NotificationItemModel {
  final String id;
  final String? memberId;
  final String type;
  final String title;
  final String message;
  final DateTime scheduledAt;
  final DateTime? triggeredAt;
  final bool isRead;
  final DateTime createdAt;

  NotificationItemModel({
    required this.id,
    this.memberId,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledAt,
    this.triggeredAt,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'type': type,
      'title': title,
      'message': message,
      'scheduledAt': scheduledAt.toIso8601String(),
      'triggeredAt': triggeredAt?.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationItemModel.fromMap(Map<String, dynamic> map) {
    return NotificationItemModel(
      id: map['id'] ?? '',
      memberId: map['memberId'],
      type: map['type'] ?? 'FEE_DUE_SOON',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      scheduledAt: DateTime.parse(map['scheduledAt']),
      triggeredAt: map['triggeredAt'] != null ? DateTime.parse(map['triggeredAt']) : null,
      isRead: (map['isRead'] ?? 0) == 1,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}

