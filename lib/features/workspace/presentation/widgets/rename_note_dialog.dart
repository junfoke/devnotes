import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class RenameNoteDialog extends StatefulWidget {
  final String currentTitle;

  const RenameNoteDialog({super.key, required this.currentTitle});

  @override
  State<RenameNoteDialog> createState() => _RenameNoteDialogState();
}

class _RenameNoteDialogState extends State<RenameNoteDialog> {
  late final TextEditingController _controller;

  /// Validation message shown under the field, null when valid.
  String? _error;

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
    final l = context.l10n;

    return AlertDialog(
      backgroundColor: colors.bgSecondary,
      title: Text(l.renameNoteTitle,
          style: TextStyle(color: colors.textPrimary)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: colors.textPrimary),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          hintText: l.newTitleHint,
          hintStyle: TextStyle(color: colors.textMuted),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel,
              style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final newTitle = _controller.text.trim();
            // Từ chối phải kèm lý do, không im lặng.
            if (newTitle.isEmpty) {
              setState(() => _error = l.titleRequired);
              return;
            }
            if (newTitle == widget.currentTitle) {
              setState(() => _error = l.titleMustDiffer);
              return;
            }
            Navigator.pop(context, newTitle);
          },
          child: Text(l.commonRename, style: TextStyle(color: colors.accent)),
        ),
      ],
    );
  }
}
