import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'help_category_screen.dart';
import 'help_content.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<HelpCategory, HelpTopic>> get _searchResults {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return allHelpTopics.where((entry) {
      final topic = entry.value;
      return topic.title.toLowerCase().contains(q) ||
          topic.body.toLowerCase().contains(q) ||
          entry.key.title.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final isSearching = _query.trim().isNotEmpty;
    final results = _searchResults;

    return Scaffold(
      appBar: AppBar(title: const Text('HELP CENTER')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search how a feature works...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _query = '';
                          }),
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: isSearching
                  ? (results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No help articles match "${_query.trim()}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(20, 8, 20, safeBottom + 24),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final entry = results[index];
                            return _HelpResultTile(
                              category: entry.key,
                              topic: entry.value,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HelpCategoryScreen(
                                    category: entry.key,
                                    highlightTopicTitle: entry.value.title,
                                  ),
                                ),
                              ),
                            );
                          },
                        ))
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, safeBottom + 24),
                      itemCount: helpCategories.length,
                      itemBuilder: (context, index) {
                        final category = helpCategories[index];
                        return _HelpCategoryTile(
                          category: category,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HelpCategoryScreen(category: category)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCategoryTile extends StatelessWidget {
  final HelpCategory category;
  final VoidCallback onTap;

  const _HelpCategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.neonLime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, color: AppTheme.neonLime, size: 22),
        ),
        title: Text(
          category.title,
          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          category.description,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}

class _HelpResultTile extends StatelessWidget {
  final HelpCategory category;
  final HelpTopic topic;
  final VoidCallback onTap;

  const _HelpResultTile({required this.category, required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(category.icon, color: AppTheme.neonLime, size: 20),
        title: Text(
          topic.title,
          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13.5),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          category.title,
          style: TextStyle(color: AppTheme.neonLime, fontSize: 10.5, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
