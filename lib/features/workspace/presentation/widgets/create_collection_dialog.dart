import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';

/// Dialog tạo collection mới, hoặc sửa [initial] nếu được truyền vào.
///
/// Trả về `{'name': String, 'tags': List<String>}`, hoặc null nếu hủy.
class CreateCollectionDialog extends StatefulWidget {
  const CreateCollectionDialog({super.key, this.initial});

  final Collection? initial;

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  late final _nameController =
      TextEditingController(text: widget.initial?.name ?? '');
  late final _tagsController =
      TextEditingController(text: widget.initial?.filterTags.join(', ') ?? '');

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    return AlertDialog(
      backgroundColor: colors.bgSecondary,
      title: Text(_isEdit ? l.editCollectionTitle : l.newCollectionTitle,
          style: TextStyle(color: colors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l.collectionNameHint,
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l.filterTagsHint,
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
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final tags = _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            Navigator.pop(context, {'name': name, 'tags': tags});
          },
          child: Text(_isEdit ? l.commonSave : l.commonCreate,
              style: TextStyle(color: colors.accent)),
        ),
      ],
    );
  }
}
