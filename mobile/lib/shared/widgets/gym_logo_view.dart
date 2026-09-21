import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GymLogoView extends StatelessWidget {
  final String? logoPath;
  final double size;
  final double borderRadius;
  final bool hasBorder;
  final bool isCircle;
  final BoxFit fit;

  const GymLogoView({
    super.key,
    this.logoPath,
    this.size = 48,
    this.borderRadius = 0,
    this.hasBorder = false,
    this.isCircle = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomFile = logoPath != null &&
        logoPath!.isNotEmpty &&
        File(logoPath!).existsSync();

    Widget image = hasCustomFile
        ? Image.file(
            File(logoPath!),
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/logo.png',
              width: size,
              height: size,
              fit: fit,
            ),
          )
        : Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: fit,
          );

    if (isCircle || borderRadius > 0) {
      image = ClipRRect(
        borderRadius: isCircle
            ? BorderRadius.circular(size / 2)
            : BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    if (hasBorder) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppTheme.neonLime.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: image,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: image,
    );
  }
}
