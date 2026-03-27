import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class RenameNoteDialog extends StatefulWidget {
  final String currentTitle;

  const RenameNoteDialog({super.key, required this.currentTitle});

  @override
  State<RenameNoteDialog> createState() => _RenameNoteDialogState();
}

class _RenameNoteDialogState extends State<RenameNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return AlertDialog(
      backgroundColor: colors.bgSecondary,
      title: Text('Rename Note', style: TextStyle(color: colors.textPrimary)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'New title',
          hintStyle: TextStyle(color: colors.textMuted),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final newTitle = _controller.text.trim();
            if (newTitle.isEmpty || newTitle == widget.currentTitle) return;
            Navigator.pop(context, newTitle);
          },
          child: Text('Rename', style: TextStyle(color: colors.accent)),
        ),
      ],
    );
  }
}
