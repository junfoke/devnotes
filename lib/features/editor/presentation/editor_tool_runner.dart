import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/editor/domain/editor_tool.dart';
import 'package:devnotes/features/editor/domain/text_ops.dart';
import 'package:devnotes/features/editor/domain/toolbar_item.dart';

/// Thực thi một công cụ soạn thảo theo id.
///
/// Mọi thao tác sửa văn bản chỉ gán `text.value` — listener tự lưu và lớp
/// chặn ghi đè thay đổi từ bên ngoài trong `EditorScreen` bắt được (B-01).
class EditorToolRunner {
  final TextEditingController text;
  final UndoHistoryController undo;
  final BuildContext context;
  final WidgetRef ref;

  EditorToolRunner({
    required this.text,
    required this.undo,
    required this.context,
    required this.ref,
  });

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
      default:
        final item = markdownItemFor(id);
        if (item != null) _insertSyntax(item);
    }
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
