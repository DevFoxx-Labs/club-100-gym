import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loads the gym's logo into a [pw.ImageProvider] for embedding in generated
/// bill/receipt PDFs.
///
/// Decodes via Flutter's own image codec (the same one [Image.file] uses to
/// preview the logo in-app) rather than the `pdf` package's bundled pure-Dart
/// decoder, which doesn't understand every format a camera/gallery can
/// produce (e.g. HEIC). The decoded frame is then handed to the `pdf`
/// package as raw RGBA pixels via [pw.RawImage], so it never needs to
/// re-decode the original bytes itself.
///
/// Falls back to the app's bundled default logo when no custom logo has
/// been set (or the saved file is missing), matching [GymLogoView] and
/// [EditableGymLogo], which show the same bundled asset elsewhere in the
/// app — without this, a receipt could look "logo-less" even though the
/// admin sees a logo everywhere else in the UI.
class PdfLogoLoader {
  static const String _defaultLogoAsset = 'assets/images/logo.png';

  static Future<pw.ImageProvider?> load(String? logoPath) async {
    try {
      Uint8List? bytes;
      if (logoPath != null && logoPath.trim().isNotEmpty) {
        final file = File(logoPath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }
      bytes ??= (await rootBundle.load(_defaultLogoAsset)).buffer.asUint8List();

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      return pw.RawImage(
        bytes: byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PdfLogoLoader: failed to load logo (path=$logoPath): $e');
      }
      return null;
    }
  }
}
