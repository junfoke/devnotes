import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class CreateNoteDialog extends StatefulWidget {
  const CreateNoteDialog({super.key});

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return AlertDialog(
      backgroundColor: colors.bgSecondary,
      title: Text('New Note', style: TextStyle(color: colors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Note title',
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tags (comma separated)',
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
            final tags = _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            Navigator.pop(context, {'title': title, 'tags': tags});
          },
          child: Text('Create', style: TextStyle(color: colors.accent)),
        ),
      ],
    );
  }
}
