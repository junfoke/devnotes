import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class WorkspaceAppBar extends StatelessWidget {
  final VoidCallback onSyncTap;
  final VoidCallback onGitStatusTap;
  final Color gitStatusColor;

  const WorkspaceAppBar({
    super.key,
    required this.onSyncTap,
    required this.onGitStatusTap,
    required this.gitStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DevNotes',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: onGitStatusTap,
                  child: Row(
                    children: [
                      Icon(Icons.commit, size: 20, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gitStatusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onSyncTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 16, color: colors.textOnAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Sync Now',
                          style: TextStyle(
                            color: colors.textOnAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
