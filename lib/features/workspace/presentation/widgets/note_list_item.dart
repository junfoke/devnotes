import 'package:flutter/material.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';

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

  String _timeAgo(AppLocalizations l, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return l.timeDaysAgo(diff.inDays);
    if (diff.inHours > 0) return l.timeHoursAgo(diff.inHours);
    if (diff.inMinutes > 0) return l.timeMinutesAgo(diff.inMinutes);
    return l.timeJustNow;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;

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
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? l.untitled : note.title,
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
                _timeAgo(l, note.updatedAt),
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
