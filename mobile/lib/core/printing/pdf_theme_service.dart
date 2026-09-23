import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loads the bundled Hind font and builds a document-wide PDF theme.
///
/// The `pdf` package's default base-14 fonts (Helvetica) do not contain the
/// ₹ (Indian Rupee, U+20B9) glyph, so it renders as a blank box. Hind is a
/// static (non-variable) OFL font verified to include this glyph.
class PdfThemeService {
  static pw.ThemeData? _cachedTheme;

  static Future<pw.ThemeData> getTheme() async {
    final cached = _cachedTheme;
    if (cached != null) return cached;

    final regularData = await rootBundle.load('assets/fonts/Hind-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Hind-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);

    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: regular,
      boldItalic: bold,
    );
    _cachedTheme = theme;
    return theme;
  }
}
