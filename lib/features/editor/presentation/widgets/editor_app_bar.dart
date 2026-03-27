import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';

class EditorAppBar extends StatelessWidget {
  final SaveStatus saveStatus;
  final int currentPage;
  final Future<void> Function() onBack;
  final VoidCallback onMore;

  const EditorAppBar({
    super.key,
    required this.saveStatus,
    required this.currentPage,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              onPressed: onBack,
            ),
            const Spacer(),
            // Save status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: saveStatus == SaveStatus.saved
                    ? colors.success
                    : saveStatus == SaveStatus.saving
                        ? colors.warning
                        : colors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            // Page indicator dots
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == 0
                        ? colors.accent
                        : colors.textMuted.withAlpha(100),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == 1
                        ? colors.accent
                        : colors.textMuted.withAlpha(100),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.textSecondary),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}
