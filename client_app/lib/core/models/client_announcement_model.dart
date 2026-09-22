import 'package:flutter/material.dart';
import '../theme/client_theme.dart';

class ClientAnnouncementModel {
  final String id;
  final String? title;
  final String message;
  final String? imagePath;
  final String category; // 'class', 'equipment', 'hours', 'event', 'maintenance', 'general'
  final bool isPinned;
  final bool isImportant;
  final DateTime createdAt;
  final bool isRead;

  ClientAnnouncementModel({
    required this.id,
    this.title,
    required this.message,
    this.imagePath,
    this.category = 'general',
    this.isPinned = false,
    this.isImportant = false,
    required this.createdAt,
    this.isRead = false,
  });

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    final firstLine = message.split('\n').first.trim();
    return firstLine.isNotEmpty ? firstLine : 'Gym Announcement';
  }

  ({IconData icon, Color iconColor, Color bgColor, String label}) get visuals {
    switch (category) {
      case 'class':
        return (
          icon: Icons.calendar_month_rounded,
          iconColor: ClientTheme.classGreen,
          bgColor: ClientTheme.classGreenBg,
          label: 'Class / Workout',
        );
      case 'equipment':
        return (
          icon: Icons.fitness_center_rounded,
          iconColor: ClientTheme.equipBlue,
          bgColor: ClientTheme.equipBlueBg,
          label: 'Equipment',
        );
      case 'hours':
        return (
          icon: Icons.access_time_filled_rounded,
          iconColor: ClientTheme.hoursAmber,
          bgColor: ClientTheme.hoursAmberBg,
          label: 'Gym Hours',
        );
      case 'event':
        return (
          icon: Icons.emoji_events_rounded,
          iconColor: ClientTheme.eventPurple,
          bgColor: ClientTheme.eventPurpleBg,
          label: 'Events & Offers',
        );
      case 'maintenance':
        return (
          icon: Icons.warning_rounded,
          iconColor: ClientTheme.alertRed,
          bgColor: ClientTheme.alertRedBg,
          label: 'Notice & Maintenance',
        );
      default:
        return (
          icon: Icons.campaign_rounded,
          iconColor: ClientTheme.neonLime,
          bgColor: ClientTheme.classGreenBg,
          label: 'Announcement',
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'imagePath': imagePath,
      'category': category,
      'isPinned': isPinned ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  factory ClientAnnouncementModel.fromMap(Map<String, dynamic> map, {bool isRead = false}) {
    return ClientAnnouncementModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString(),
      message: map['message']?.toString() ?? '',
      imagePath: map['imagePath']?.toString(),
      category: map['category']?.toString() ?? 'general',
      isPinned: (map['isPinned'] == 1 || map['isPinned'] == true),
      isImportant: (map['isImportant'] == 1 || map['isImportant'] == true),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : (map['sentAt'] != null
              ? DateTime.tryParse(map['sentAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isRead: isRead,
    );
  }

  ClientAnnouncementModel copyWith({
    String? title,
    String? message,
    String? imagePath,
    String? category,
    bool? isPinned,
    bool? isImportant,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ClientAnnouncementModel(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
