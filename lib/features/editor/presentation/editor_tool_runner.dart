import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/features/editor/domain/editor_tool.dart';
import 'package:devnotes/features/editor/domain/text_ops.dart';
import 'package:devnotes/features/editor/domain/toolbar_item.dart';
import 'package:devnotes/features/editor/presentation/editor_display_actions.dart';
import 'package:devnotes/features/editor/presentation/widgets/tool_pickers.dart';

/// Thực thi một công cụ soạn thảo theo id.
///
/// Mọi thao tác sửa văn bản chỉ gán `text.value` — listener tự lưu và lớp
/// chặn ghi đè thay đổi từ bên ngoài trong `EditorScreen` bắt được (B-01).
class EditorToolRunner {
  final TextEditingController text;
  final UndoHistoryController undo;
  final BuildContext context;
  final WidgetRef ref;

  /// Hiện thanh tìm & thay thế của editor (`find_replace`).
  final VoidCallback? onFindReplace;

  EditorToolRunner({
    required this.text,
    required this.undo,
    required this.context,
    required this.ref,
    this.onFindReplace,
  });

  /// Đổi cài đặt hiển thị — dùng chung với nhóm Hiển thị của bảng công cụ.
  EditorDisplayActions get display => EditorDisplayActions(context);

  /// Id chưa hỗ trợ thì bỏ qua.
  Future<void> run(String id) async {
    switch (id) {
      case 'undo':
        undo.undo();
      case 'redo':
        undo.redo();
      case 'indent':
        text.value = indentLines(text.value);
      case 'outdent':
        text.value = outdentLines(text.value);
      case 'move_up':
        text.value = moveLines(text.value, up: true);
      case 'move_down':
        text.value = moveLines(text.value, up: false);
      case 'duplicate_line':
        text.value = duplicateLines(text.value);
      case 'delete_line':
        text.value = deleteLines(text.value);
      case 'find_replace':
        onFindReplace?.call();
      case 'date_time':
        _insert(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
      case 'table':
        await _insertTable();
      case 'code_block':
        await _insertCodeBlock();
      case 'symbols':
        await showSymbolsSheet(context, onInsert: insertSymbol);
      case 'template':
        await _insertTemplate();
      // Nhóm Hiển thị khi được ghim lên thanh công cụ (ruling R2).
      case 'font':
        await display.cycleFont();
      case 'size_down':
        await display.changeFontSize(-1);
      case 'size_up':
        await display.changeFontSize(1);
      case 'line_height':
        await display.cycleLineHeight();
      case 'word_wrap':
        await display.toggleWordWrap();
      case 'focus_mode':
        await display.toggleFocusMode();
      case 'theme':
        await display.toggleTheme();
      default:
        final item = markdownItemFor(id);
        if (item != null) _insertSyntax(item);
    }
  }

  /// Chèn ký tự tại con trỏ (hàng chip `symbols`).
  void insertSymbol(String symbol) => _insert(symbol);

  void _insert(String s, {bool asBlock = false}) {
    text.value = insertAtCursor(text.value, s, asBlock: asBlock);
  }

  Future<void> _insertTable() async {
    final l = context.l10n;
    final picked = await showTablePicker(context);
    if (picked == null || !context.mounted) return;
    final headers = [
      for (var i = 1; i <= picked.columns; i++) l.tableColumnHeader(i),
    ];
    _insert(buildTable(headers, picked.rows), asBlock: true);
  }

  Future<void> _insertCodeBlock() async {
    final lang = await showCodeLanguagePicker(context);
    if (lang == null || !context.mounted) return;
    final v = insertAtCursor(text.value, buildCodeBlock(lang), asBlock: true);
    // Con trỏ vào dòng trống giữa khối: trước "\n```" cuối.
    text.value = TextEditingValue(
      text: v.text,
      selection: TextSelection.collapsed(offset: v.selection.baseOffset - 4),
    );
  }

  Future<void> _insertTemplate() async {
    final lang = Localizations.localeOf(context).languageCode;
    final t = await showTemplatePicker(context, lang);
    if (t == null || !context.mounted) return;
    _insert(t.body, asBlock: true);
  }

  /// Chèn cú pháp Markdown quanh vùng chọn. Không có con trỏ thì chèn cuối.
  void _insertSyntax(ToolbarItem item) {
    final value = text.text;
    final selection = text.selection;

    final rawStart = selection.start;
    final start = rawStart < 0
        ? value.length
        : min(selection.start, selection.end);
    final end = rawStart < 0
        ? value.length
        : max(selection.start, selection.end);
    final selectedText = value.substring(start, end);

    // Mục dạng khối phải bắt đầu ở dòng mới.
    var prefix = item.insertBefore;
    if (item.isBlock && start > 0 && value[start - 1] != '\n') {
      prefix = '\n$prefix';
    }

    text.value = TextEditingValue(
      text: value.replaceRange(
        start,
        end,
        '$prefix$selectedText${item.insertAfter}',
      ),
      selection: TextSelection.collapsed(
        offset: start + prefix.length + selectedText.length,
      ),
    );
  }
}
