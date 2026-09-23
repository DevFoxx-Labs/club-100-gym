import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

/// Loads the gym's custom logo (stored as a local file path) into a
/// [pw.MemoryImage] for embedding in generated bill/receipt PDFs.
class PdfLogoLoader {
  static Future<pw.MemoryImage?> load(String? logoPath) async {
    if (logoPath == null || logoPath.trim().isEmpty) return null;
    final file = File(logoPath);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}
