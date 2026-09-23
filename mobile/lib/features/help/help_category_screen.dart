import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'help_content.dart';

class HelpCategoryScreen extends StatelessWidget {
  final HelpCategory category;
  final String? highlightTopicTitle;

  const HelpCategoryScreen({super.key, required this.category, this.highlightTopicTitle});

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: Text(category.title.toUpperCase())),
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + 24),
          itemCount: category.topics.length,
          itemBuilder: (context, index) {
            final topic = category.topics[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: topic.title == highlightTopicTitle,
                  iconColor: AppTheme.neonLime,
                  collapsedIconColor: AppTheme.textMuted,
                  title: Text(
                    topic.title,
                    style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.body,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
