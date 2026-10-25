import 'package:flutter/material.dart';
import 'package:devnotes/features/editor/domain/toolbar_item.dart';

/// Nhóm hiển thị của công cụ trong bảng "Công cụ soạn thảo".
/// `format` là nhóm "Định dạng" (các nút Markdown cũ).
enum EditorToolGroup { format, display, edit, insert, view }

/// Một công cụ soạn thảo có thể ghim lên thanh công cụ.
class EditorTool {
  final String id;
  final EditorToolGroup group;
  final IconData icon;

  /// Chữ hiện thay cho icon (vd `H1`), null nếu dùng icon.
  final String? glyph;

  const EditorTool(this.id, this.group, this.icon, {this.glyph});

  static const _md = EditorToolGroup.format;
  static const _dp = EditorToolGroup.display;
  static const _ed = EditorToolGroup.edit;
  static const _in = EditorToolGroup.insert;
  static const _vw = EditorToolGroup.view;

  static const List<EditorTool> all = [
    // Định dạng: các nút Markdown cũ, giữ nguyên id.
    EditorTool('h1', _md, Icons.title, glyph: 'H1'),
    EditorTool('h2', _md, Icons.title, glyph: 'H2'),
    EditorTool('h3', _md, Icons.title, glyph: 'H3'),
    EditorTool('bold', _md, Icons.format_bold),
    EditorTool('italic', _md, Icons.format_italic),
    EditorTool('strikethrough', _md, Icons.strikethrough_s),
    EditorTool('link', _md, Icons.link),
    EditorTool('image', _md, Icons.image),
    EditorTool('code_inline', _md, Icons.code),
    EditorTool('code_block', _md, Icons.data_object, glyph: '<>'),
    EditorTool('checklist', _md, Icons.check_box_outlined),
    EditorTool('list_unordered', _md, Icons.format_list_bulleted),
    EditorTool('list_ordered', _md, Icons.format_list_numbered),
    EditorTool('quote', _md, Icons.format_quote),
    EditorTool('table', _md, Icons.table_chart),
    EditorTool('hr', _md, Icons.horizontal_rule),
    // Hiển thị.
    EditorTool('font', _dp, Icons.font_download_outlined),
    EditorTool('size_down', _dp, Icons.text_decrease),
    EditorTool('size_up', _dp, Icons.text_increase),
    EditorTool('line_height', _dp, Icons.format_line_spacing),
    EditorTool('word_wrap', _dp, Icons.wrap_text),
    EditorTool('focus_mode', _dp, Icons.center_focus_strong_outlined),
    EditorTool('theme', _dp, Icons.palette_outlined),
    // Chỉnh sửa.
    EditorTool('undo', _ed, Icons.undo),
    EditorTool('redo', _ed, Icons.redo),
    EditorTool('indent', _ed, Icons.format_indent_increase),
    EditorTool('outdent', _ed, Icons.format_indent_decrease),
    EditorTool('move_up', _ed, Icons.arrow_upward),
    EditorTool('move_down', _ed, Icons.arrow_downward),
    EditorTool('duplicate_line', _ed, Icons.content_copy),
    EditorTool('delete_line', _ed, Icons.delete_outline),
    EditorTool('find_replace', _ed, Icons.find_replace),
    // Chèn.
    EditorTool('date_time', _in, Icons.event),
    EditorTool('symbols', _in, Icons.emoji_symbols),
    EditorTool('note_link', _in, Icons.note_add_outlined),
    EditorTool('template', _in, Icons.article_outlined),
    // Xem.
    EditorTool('outline', _vw, Icons.format_list_numbered_rtl),
    EditorTool('stats', _vw, Icons.bar_chart),
  ];

  static EditorTool? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Nút Markdown tương ứng với [id] (để chèn cú pháp), null nếu không phải
/// nút Markdown.
ToolbarItem? markdownItemFor(String id) {
  for (final i in ToolbarItem.allItems) {
    if (i.id == id) return i;
  }
  return null;
}
