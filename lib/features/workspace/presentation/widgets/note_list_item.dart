import 'package:flutter/material.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/utils/enums.dart';

class NoteListItem extends StatelessWidget {
  final NoteFile note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onLongPress,
  });

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Color _syncDotColor(BuildContext context) {
    final colors = Theme.of(context).appColors;
    switch (note.syncStatus) {
      case SyncStatus.synced:
        return colors.success;
      case SyncStatus.pending:
        return colors.warning;
      case SyncStatus.conflict:
      case SyncStatus.error:
        return colors.error;
      case SyncStatus.success:
        return colors.success;
      default:
        return colors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Dismissible(
      key: Key(note.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _syncDotColor(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: note.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bgSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: colors.accentLight,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _timeAgo(note.updatedAt),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
