import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF0B0C10);
  static const Color darkSurface = Color(0xFF13151B);
  static const Color darkCard = Color(0xFF1A1D26);
  static const Color darkBorder = Color(0xFF1E222D);

  /// The factory-default highlight color, used until the admin picks a favorite color
  /// in Settings, and offered as a "Reset to Default" option in the color picker.
  static const Color defaultAccentColor = Color(0xFFB5F63D);

  static Color _accentColor = defaultAccentColor;

  /// The app-wide highlight/accent color. Historically named `neonLime` because that
  /// was the original fixed brand color; kept as the name so the hundreds of existing
  /// call sites don't need to change when this became admin-customizable.
  static Color get neonLime => _accentColor;

  static void setAccentColor(Color color) {
    _accentColor = color;
  }

  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusDueSoon = Color(0xFFF59E0B);
  static const Color statusActive = Color(0xFF10B981);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        surface: darkSurface,
        primary: neonLime,
        secondary: neonLime,
        onSurface: textWhite,
        onPrimary: darkBackground,
        outline: darkBorder,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textWhite),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: neonLime,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: neonLime, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonLime,
          foregroundColor: darkBackground,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}

