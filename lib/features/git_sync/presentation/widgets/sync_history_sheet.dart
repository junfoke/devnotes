// lib/features/git_sync/presentation/widgets/sync_history_sheet.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:intl/intl.dart';

class SyncHistorySheet extends StatelessWidget {
  final String branchName;
  final DateTime? lastSyncAt;
  final List<SyncLogEntry> entries;

  const SyncHistorySheet({
    super.key,
    required this.branchName,
    this.lastSyncAt,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final dateFormat = DateFormat('MMM d, HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sync History',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  branchName,
                  style: TextStyle(
                    color: colors.accentLight,
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
            ],
          ),
          if (lastSyncAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last sync: ${dateFormat.format(lastSyncAt!)}',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No sync history yet',
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
            )
          else
            ...entries.take(20).map((entry) {
              final icon =
                  entry.success ? Icons.check_circle : Icons.error;
              final iconColor =
                  entry.success ? colors.success : colors.error;
              final actionLabel = entry.action == SyncAction.push
                  ? 'Push'
                  : entry.action == SyncAction.pull
                      ? 'Pull'
                      : 'Conflict';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$actionLabel — ${entry.filesChanged} file(s)',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          if (entry.errorMessage != null)
                            Text(
                              entry.errorMessage!,
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      dateFormat.format(entry.timestamp),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
