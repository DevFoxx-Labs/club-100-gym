import 'package:flutter/material.dart';

class ClientTheme {
  static const Color darkBackground = Color(0xFF090B10);
  static const Color darkSurface = Color(0xFF141720);
  static const Color darkCard = Color(0xFF161922);
  static const Color darkBorder = Color(0xFF222838);

  static const Color neonLime = Color(0xFF69F0AE);
  static const Color neonLimeBright = Color(0xFF76FF03);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color classGreen = Color(0xFF69F0AE);
  static const Color classGreenBg = Color(0xFF142918);

  static const Color equipBlue = Color(0xFF38BDF8);
  static const Color equipBlueBg = Color(0xFF132238);

  static const Color hoursAmber = Color(0xFFF59E0B);
  static const Color hoursAmberBg = Color(0xFF2E1C0C);

  static const Color eventPurple = Color(0xFFA855F7);
  static const Color eventPurpleBg = Color(0xFF261338);

  static const Color alertRed = Color(0xFFF43F5E);
  static const Color alertRedBg = Color(0xFF331418);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: neonLime,
        surface: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: neonLime),
      ),
    );
  }
}
