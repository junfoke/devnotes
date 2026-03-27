import 'package:flutter/material.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class SearchResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final ValueChanged<String> onTap;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          title: Text(
            result.title,
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            result.snippet.replaceAll(RegExp(r'</?b>'), ''),
            style: TextStyle(color: colors.textMuted, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onTap(result.filePath),
        );
      },
    );
  }
}
