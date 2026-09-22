import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MemberAvatar extends StatelessWidget {
  final String name;
  final String? photoPath;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final BoxBorder? border;

  const MemberAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.border,
  });

  /// Extracts up to 2 uppercase initials from a name (e.g. "Rahul Sharma" -> "RS", "Rahul" -> "R").
  static String computeInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'M';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedPath = photoPath?.trim();
    final bool hasValidPhoto = trimmedPath != null &&
        trimmedPath.isNotEmpty &&
        File(trimmedPath).existsSync();

    final bg = backgroundColor ?? AppTheme.neonLime.withValues(alpha: 0.18);
    final fg = foregroundColor ?? AppTheme.neonLime;
    final initials = computeInitials(name);

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: hasValidPhoto ? FileImage(File(trimmedPath)) : null,
      child: !hasValidPhoto
          ? Text(
              initials,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                fontSize: fontSize ?? (radius * 0.75),
              ),
            )
          : null,
    );

    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}

