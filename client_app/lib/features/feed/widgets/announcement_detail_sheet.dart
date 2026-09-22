import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/models/client_announcement_model.dart';
import '../../../core/theme/client_theme.dart';

class AnnouncementDetailSheet extends StatelessWidget {
  final ClientAnnouncementModel announcement;

  const AnnouncementDetailSheet({super.key, required this.announcement});

  static Future<void> show(BuildContext context, ClientAnnouncementModel item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ClientTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AnnouncementDetailSheet(announcement: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final visuals = announcement.visuals;
    final formattedDate = DateFormat('EEEE, dd MMM yyyy • hh:mm a').format(announcement.createdAt);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + (safeBottom > 0 ? safeBottom : 8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ClientTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header row with squircle icon & category tag
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visuals.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(visuals.icon, color: visuals.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: visuals.bgColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: visuals.iconColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              visuals.label.toUpperCase(),
                              style: TextStyle(
                                color: visuals.iconColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (announcement.isPinned) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: ClientTheme.neonLime,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PINNED',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: ClientTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ClientTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              announcement.displayTitle,
              style: const TextStyle(
                color: ClientTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Image if present
            if (announcement.imagePath != null &&
                announcement.imagePath!.isNotEmpty &&
                File(announcement.imagePath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(announcement.imagePath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Message Body inside scrollable area if long
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ClientTheme.darkBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ClientTheme.darkBorder),
                  ),
                  child: Text(
                    announcement.message,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClientTheme.textWhite,
                      side: const BorderSide(color: ClientTheme.darkBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Text', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${announcement.displayTitle}\n\n${announcement.message}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Announcement copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: ClientTheme.darkSurface,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClientTheme.neonLime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
