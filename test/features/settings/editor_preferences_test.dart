import 'package:devnotes/features/settings/data/preferences_repository.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('máy mới: ghim mặc định có hoàn tác, làm lại, thụt, lùi', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await PreferencesRepository().loadEditorPreferences();
    // Ruling R5: 4 nút chỉnh sửa đứng đầu để luôn trong tầm một chạm.
    expect(p.toolbarItems.take(5).toList(), [
      'undo',
      'redo',
      'indent',
      'outdent',
      'h1',
    ]);
  });

  test(
    'người dùng cũ đã sắp toolbar: thêm 4 nút mới lên đầu một lần, giữ thứ tự cũ',
    () async {
      SharedPreferences.setMockInitialValues({
        'editor_toolbar_items': ['bold', 'h1'],
      });
      final repo = PreferencesRepository();
      expect((await repo.loadEditorPreferences()).toolbarItems, [
        'undo',
        'redo',
        'indent',
        'outdent',
        'bold',
        'h1',
      ]);
    },
  );

  test(
    'sau di trú, user bỏ ghim "undo" thì lần tải sau không thêm lại',
    () async {
      SharedPreferences.setMockInitialValues({
        'editor_toolbar_items': ['bold'],
      });
      final repo = PreferencesRepository();
      final first = await repo.loadEditorPreferences();
      await repo.saveEditorPreferences(
        first.copyWith(
          toolbarItems: first.toolbarItems.where((e) => e != 'undo').toList(),
        ),
      );
      final second = await repo.loadEditorPreferences();
      expect(second.toolbarItems, isNot(contains('undo')));
      expect(second.toolbarItems, contains('redo'));
    },
  );

  test('lưu và đọc lại giãn dòng, tự xuống dòng, tập trung, mục ẩn', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PreferencesRepository();
    final p = await repo.loadEditorPreferences();
    expect(p.lineHeight, EditorLineHeight.normal);
    expect(p.wordWrap, isTrue);
    expect(p.focusMode, isFalse);
    expect(p.hiddenTools, isEmpty);

    await repo.saveEditorPreferences(
      p.copyWith(
        lineHeight: EditorLineHeight.relaxed,
        wordWrap: false,
        focusMode: true,
        hiddenTools: ['table', 'hr'],
      ),
    );
    final r = await repo.loadEditorPreferences();
    expect(r.lineHeight, EditorLineHeight.relaxed);
    expect(r.wordWrap, isFalse);
    expect(r.focusMode, isTrue);
    expect(r.hiddenTools, ['table', 'hr']);
  });

  test('giá trị giãn dòng lạ trong prefs thì về normal', () async {
    SharedPreferences.setMockInitialValues({'editor_line_height': 'xyz'});
    final p = await PreferencesRepository().loadEditorPreferences();
    expect(p.lineHeight, EditorLineHeight.normal);
  });

  test('hệ số giãn dòng và font hệ thống', () {
    expect(EditorLineHeight.compact.value, 1.35);
    expect(EditorLineHeight.normal.value, 1.6);
    expect(EditorLineHeight.relaxed.value, 1.9);
    expect(const EditorPreferences().fontFamilyOrNull, 'JetBrainsMono');
    expect(
      const EditorPreferences(
        fontFamily: EditorPreferences.systemFont,
      ).fontFamilyOrNull,
      isNull,
    );
  });
}
