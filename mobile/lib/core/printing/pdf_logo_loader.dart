import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

/// Loads the gym's custom logo (stored as a local file path) into a
/// [pw.ImageProvider] for embedding in generated bill/receipt PDFs.
///
/// Decodes via Flutter's own image codec (the same one [Image.file] uses to
/// preview the logo in-app) rather than the `pdf` package's bundled pure-Dart
/// decoder, which doesn't understand every format a camera/gallery can
/// produce (e.g. HEIC). The decoded frame is then handed to the `pdf`
/// package as raw RGBA pixels via [pw.RawImage], so it never needs to
/// re-decode the original bytes itself.
class PdfLogoLoader {
  static Future<pw.ImageProvider?> load(String? logoPath) async {
    if (logoPath == null || logoPath.trim().isEmpty) return null;
    final file = File(logoPath);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      return pw.RawImage(
        bytes: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PdfLogoLoader: failed to load logo at $logoPath: $e');
      }
      return null;
    }
  }
}
