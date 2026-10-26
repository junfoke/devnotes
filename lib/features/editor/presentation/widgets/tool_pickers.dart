import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/features/editor/domain/note_templates.dart';

/// Ngôn ngữ khối code gợi ý.
const codeLanguages = [
  'dart',
  'kotlin',
  'swift',
  'js',
  'ts',
  'python',
  'java',
  'go',
  'rust',
  'sql',
  'bash',
  'json',
  'yaml',
  'html',
  'css',
  'markdown',
  'plaintext',
];

/// Ký tự hay dùng khi viết code/Markdown.
const codeSymbols = [
  '`', '{', '}', '[', ']', '(', ')', '|', '<', '>', '~', '#', '*', '_', '=', //
];

/// Chọn số cột (2–6) và số hàng (1–10). Hủy trả về null.
Future<({int columns, int rows})?> showTablePicker(BuildContext context) {
  return showDialog<({int columns, int rows})>(
    context: context,
    builder: (_) => const _TablePickerDialog(),
  );
}

class _TablePickerDialog extends StatefulWidget {
  const _TablePickerDialog();

  @override
  State<_TablePickerDialog> createState() => _TablePickerDialogState();
}

class _TablePickerDialogState extends State<_TablePickerDialog> {
  int _columns = 3;
  int _rows = 2;

  Widget _stepper(
    String keyName,
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          key: Key('$keyName-dec'),
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            key: Key('$keyName-value'),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          key: Key('$keyName-inc'),
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      key: const Key('table-picker'),
      title: Text(l.toolbarItemTable),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepper(
            'table-columns',
            l.tablePickerColumns,
            _columns,
            2,
            6,
            (v) => setState(() => _columns = v),
          ),
          _stepper(
            'table-rows',
            l.tablePickerRows,
            _rows,
            1,
            10,
            (v) => setState(() => _rows = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: const Key('table-insert'),
          onPressed: () =>
              Navigator.pop(context, (columns: _columns, rows: _rows)),
          child: Text(l.tablePickerInsert),
        ),
      ],
    );
  }
}

/// Chọn ngôn ngữ cho khối code. Hủy trả về null.
Future<String?> showCodeLanguagePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Column(
        key: const Key('code-language-picker'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              ctx.l10n.codeLanguageTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final lang in codeLanguages)
                    ActionChip(
                      key: Key('code-lang-$lang'),
                      label: Text(lang),
                      onPressed: () => Navigator.pop(ctx, lang),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Chọn một mẫu ghi chú. Hủy trả về null.
Future<NoteTemplate?> showTemplatePicker(
  BuildContext context,
  String languageCode,
) {
  return showModalBottomSheet<NoteTemplate>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        key: const Key('template-picker'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              ctx.l10n.templatePickerTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          for (final t in builtInTemplates(languageCode))
            ListTile(
              key: Key('template-${t.id}'),
              leading: const Icon(Icons.article_outlined),
              title: Text(t.title),
              onTap: () => Navigator.pop(ctx, t),
            ),
        ],
      ),
    ),
  );
}

/// Hàng chip ký tự; [onInsert] gọi với ký tự được bấm.
class SymbolRow extends StatelessWidget {
  const SymbolRow({super.key, required this.onInsert});

  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('symbol-row'),
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final s in codeSymbols)
          ActionChip(
            key: Key('symbol-$s'),
            label: Text(s, style: const TextStyle(fontFamily: 'JetBrainsMono')),
            onPressed: () => onInsert(s),
          ),
      ],
    );
  }
}

/// Bảng nhỏ chỉ có hàng ký tự (khi `symbols` bấm từ thanh công cụ); giữ mở
/// cho tới khi người dùng vuốt đóng.
Future<void> showSymbolsSheet(
  BuildContext context, {
  required ValueChanged<String> onInsert,
}) {
  return showModalBottomSheet<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SymbolRow(onInsert: onInsert),
      ),
    ),
  );
}
