import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GymLogoView extends StatelessWidget {
  final String? logoPath;
  final double size;
  final double borderRadius;
  final bool hasBorder;
  final bool isCircle;

  const GymLogoView({
    super.key,
    this.logoPath,
    this.size = 48,
    this.borderRadius = 14,
    this.hasBorder = true,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomFile = logoPath != null &&
        logoPath!.isNotEmpty &&
        File(logoPath!).existsSync();

    final effectiveRadius = isCircle ? size / 2 : borderRadius;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(color: AppTheme.neonLime.withValues(alpha: 0.35), width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: hasCustomFile
            ? Image.file(
                File(logoPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/logo.png',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                'assets/images/logo.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
