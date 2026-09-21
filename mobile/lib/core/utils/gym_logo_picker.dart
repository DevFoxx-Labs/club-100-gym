import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<String> _saveGymLogo(String sourcePath) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final logoDir = Directory(p.join(docsDir.path, 'gym_logo'));
  if (!await logoDir.exists()) {
    await logoDir.create(recursive: true);
  }
  final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
  final destPath = p.join(logoDir.path, '${const Uuid().v4()}$ext');
  await File(sourcePath).copy(destPath);
  return destPath;
}

Future<void> _deleteGymLogo(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

enum _LogoAction { camera, gallery, remove }

Future<String?> pickGymLogo({
  required BuildContext context,
  required String? currentPath,
}) async {
  final action = await showModalBottomSheet<_LogoAction>(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFD4FF00)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, _LogoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFD4FF00)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, _LogoAction.gallery),
            ),
            if (currentPath != null && currentPath.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                title: const Text('Remove Logo', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, _LogoAction.remove),
              ),
          ],
        ),
      ),
    ),
  );

  if (action == null) return null;

  if (action == _LogoAction.remove) {
    await _deleteGymLogo(currentPath);
    return '';
  }

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: action == _LogoAction.camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1024,
    imageQuality: 90,
  );
  if (picked == null) return null;

  final savedPath = await _saveGymLogo(picked.path);
  await _deleteGymLogo(currentPath);
  return savedPath;
}

class EditableGymLogo extends StatelessWidget {
  const EditableGymLogo({
    super.key,
    required this.logoPath,
    this.onChanged,
    this.onLogoChanged,
    this.size = 80,
  });

  final String? logoPath;
  final ValueChanged<String?>? onChanged;
  final ValueChanged<String?>? onLogoChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath != null && logoPath!.isNotEmpty && File(logoPath!).existsSync();

    return Center(
      child: GestureDetector(
        onTap: () async {
          final cb = onLogoChanged ?? onChanged;
          if (cb != null) {
            final result = await pickGymLogo(context: context, currentPath: logoPath);
            if (result != null) {
              cb(result.isEmpty ? null : result);
            }
          }
        },
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF252525),
                border: Border.all(color: const Color(0xFFD4FF00), width: 2),
                image: hasLogo
                    ? DecorationImage(
                        image: FileImage(File(logoPath!)),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFD4FF00),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Color(0xFF121212),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

