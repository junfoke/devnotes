// lib/features/git_sync/presentation/widgets/sync_history_sheet.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
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
    final l = context.l10n;
    // Theo ngôn ngữ đang chọn ("Oct 25, 20:06" / "thg 10 25, 20:06"). Dữ liệu
    // ngày giờ của intl được flutter_localizations nạp sẵn cho en và vi.
    final dateFormat = DateFormat(
      'MMM d, HH:mm',
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      // Sheet cao tối đa 70% màn hình; phần danh sách bên trong tự cuộn.
      // Không có ràng buộc này thì 20 bản ghi làm vỡ layout.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
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
                l.syncHistoryTitle,
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
                l.syncHistoryLastSync(
                    dateFormat.format(lastSyncAt!.toLocal())),
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l.syncHistoryEmpty,
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length > 20 ? 20 : entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final icon =
                      entry.success ? Icons.check_circle : Icons.error;
                  final iconColor =
                      entry.success ? colors.success : colors.error;
                  // Tên lệnh git giữ nguyên, không dịch.
                  final actionLabel = switch (entry.action) {
                    SyncAction.push => 'Push',
                    SyncAction.pull => 'Pull',
                    SyncAction.commit => 'Commit',
                    SyncAction.fetch => 'Fetch',
                  };

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 18, color: iconColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.syncHistoryEntry(
                                    actionLabel, entry.filesChanged),
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
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(entry.timestamp.toLocal()),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
