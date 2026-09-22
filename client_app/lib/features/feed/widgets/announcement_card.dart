import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/client_announcement_model.dart';
import '../../../core/theme/client_theme.dart';

class AnnouncementCard extends StatelessWidget {
  final ClientAnnouncementModel announcement;
  final VoidCallback onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = announcement.visuals;
    final date = announcement.createdAt;
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    final timeStr = DateFormat('hh:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ClientTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: announcement.isPinned
              ? ClientTheme.neonLime.withValues(alpha: 0.4)
              : (announcement.isRead ? ClientTheme.darkBorder : ClientTheme.neonLime.withValues(alpha: 0.2)),
          width: announcement.isPinned ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Squircle Category Badge
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

                    // Title and Category Label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  announcement.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ClientTheme.textWhite,
                                    fontWeight: announcement.isRead ? FontWeight.w700 : FontWeight.w900,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              if (announcement.isPinned) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ClientTheme.neonLime,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Pinned',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                              if (!announcement.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: ClientTheme.neonLime,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            visuals.label,
                            style: TextStyle(
                              color: visuals.iconColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Stacked Date & Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(color: ClientTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(color: ClientTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Announcement Message Snippet
                Text(
                  announcement.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
