import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../shared/widgets/member_avatar.dart';

Future<String> _savePhoto(String sourcePath, {String subfolder = 'profile_photos'}) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory(p.join(docsDir.path, subfolder));
  if (!await photosDir.exists()) {
    await photosDir.create(recursive: true);
  }
  final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
  final destPath = p.join(photosDir.path, '${const Uuid().v4()}$ext');
  await File(sourcePath).copy(destPath);
  return destPath;
}

Future<void> _deletePhoto(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

enum _PhotoAction { camera, gallery, remove }

Future<String?> pickProfilePhoto({
  required BuildContext context,
  required String? currentPath,
  String subfolder = 'profile_photos',
}) async {
  final source = await showModalBottomSheet<_PhotoAction>(
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
              onTap: () => Navigator.pop(context, _PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFD4FF00)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, _PhotoAction.gallery),
            ),
            if (currentPath != null && currentPath.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                title: const Text('Remove Photo', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return null;

  if (source == _PhotoAction.remove) {
    await _deletePhoto(currentPath);
    return '';
  }

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source == _PhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1024,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final savedPath = await _savePhoto(picked.path, subfolder: subfolder);
  await _deletePhoto(currentPath);
  return savedPath;
}

Future<String?> pickMemberPhoto({
  required BuildContext context,
  required String? currentPath,
}) => pickProfilePhoto(context: context, currentPath: currentPath, subfolder: 'member_photos');

Future<String?> pickTrainerPhoto({
  required BuildContext context,
  required String? currentPath,
}) => pickProfilePhoto(context: context, currentPath: currentPath, subfolder: 'trainer_photos');

class EditableMemberAvatar extends StatelessWidget {
  final String? name;
  final String? photoPath;
  final ValueChanged<String?>? onChanged;
  final ValueChanged<String?>? onPhotoChanged;
  final double radius;
  final String defaultInitials;
  final String subfolder;

  const EditableMemberAvatar({
    super.key,
    this.name,
    required this.photoPath,
    this.onChanged,
    this.onPhotoChanged,
    this.radius = 48,
    this.defaultInitials = 'M',
    this.subfolder = 'member_photos',
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty && File(photoPath!).existsSync();
    final initials = (name != null && name!.trim().isNotEmpty)
        ? MemberAvatar.computeInitials(name!)
        : defaultInitials;

    return Center(
      child: GestureDetector(
        onTap: () async {
          final cb = onPhotoChanged ?? onChanged;
          if (cb == null) return;
          final result = await pickProfilePhoto(context: context, currentPath: photoPath, subfolder: subfolder);
          if (result != null) {
            cb(result.isEmpty ? null : result);
          }
        },
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4FF00), width: 2),
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: const Color(0xFF252525),
                backgroundImage: hasPhoto ? FileImage(File(photoPath!)) : null,
                child: !hasPhoto
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: const Color(0xFFD4FF00),
                          fontSize: radius * 0.7,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
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
                size: 16,
                color: Color(0xFF121212),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef EditableProfileAvatar = EditableMemberAvatar;
typedef EditableTrainerAvatar = EditableMemberAvatar;
