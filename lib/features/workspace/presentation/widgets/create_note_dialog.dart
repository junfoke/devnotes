import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class CreateNoteDialog extends StatefulWidget {
  const CreateNoteDialog({super.key});

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();

  /// Validation message shown under the title field, null when valid.
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;

    return AlertDialog(
      backgroundColor: colors.bgSecondary,
      title: Text(l.newNote, style: TextStyle(color: colors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            decoration: InputDecoration(
              hintText: l.noteTitleHint,
              hintStyle: TextStyle(color: colors.textMuted),
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l.tagsHint,
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel,
              style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final title = _titleController.text.trim();
            // Tiêu đề rỗng phải báo lỗi rõ ràng, không im lặng.
            if (title.isEmpty) {
              setState(() => _titleError = l.titleRequired);
              return;
            }
            final tags = _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            Navigator.pop(context, {'title': title, 'tags': tags});
          },
          child: Text(l.commonCreate, style: TextStyle(color: colors.accent)),
        ),
      ],
    );
  }
}
