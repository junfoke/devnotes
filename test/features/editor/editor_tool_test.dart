import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/editor/domain/editor_tool.dart';
import 'package:devnotes/features/editor/presentation/editor_tool_labels.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/l10n/app_localizations.dart';

void main() {
  test('id không trùng và mọi id cũ của toolbar vẫn còn', () {
    final ids = EditorTool.all.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, containsAll(EditorPreferences.defaultToolbarItems));
  });

  test('mọi công cụ có nhãn ở cả tiếng Việt và tiếng Anh', () async {
    for (final locale in const [Locale('vi'), Locale('en')]) {
      final l = await AppLocalizations.delegate.load(locale);
      final labels = <String>{};
      for (final t in EditorTool.all) {
        final label = editorToolLabel(l, t.id);
        expect(label, isNot(t.id));
        expect(label, isNotEmpty);
        labels.add(label);
      }
      // Nhãn là tooltip nên phải khác nhau.
      expect(labels.length, EditorTool.all.length);
    }
  });

  test('id lạ trả về null, không ném lỗi', () {
    expect(EditorTool.byId('khong-co'), isNull);
    expect(EditorTool.byId('indent')?.group, EditorToolGroup.edit);
  });

  test('markdownItemFor chỉ trả về nút Markdown', () {
    expect(markdownItemFor('bold')?.insertBefore, '**');
    expect(markdownItemFor('indent'), isNull);
  });

  // Nút trong bảng và tiêu đề bộ chọn phải cùng một tên — user bấm "Mục lục"
  // thì thấy bảng "Mục lục", không phải "Dàn ý".
  test('nhãn công cụ outline trùng tiêu đề bộ chọn mục lục', () async {
    for (final locale in const [Locale('vi'), Locale('en')]) {
      final l = await AppLocalizations.delegate.load(locale);
      expect(editorToolLabel(l, 'outline'), l.outlineTitle, reason: '$locale');
    }
    final vi = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(vi.outlineTitle, 'Mục lục');
  });
}
