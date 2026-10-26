// Nhóm Chèn: ngày giờ, bảng, khối code, ký tự, mẫu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/l10n/app_localizations.dart';
import 'package:devnotes/l10n/app_localizations_vi.dart';

import 'in_memory_note_repository.dart';

void main() {
  late InMemoryNoteRepository repo;
  late ProviderContainer container;
  final l = AppLocalizationsVi();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tooltip_editor': true});
    repo = InMemoryNoteRepository();
    container = ProviderContainer(
      overrides: [noteFileRepositoryProvider.overrideWith((ref) async => repo)],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpEditor(WidgetTester tester, String content) async {
    final note = repo.seed(fileName: 'ghi-chu.md', content: content);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          theme: AppTheme.light(),
          home: EditorScreen(filePath: note.filePath),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  TextEditingController editor(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!;

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editor-tools-button')));
    await tester.pumpAndSettle();
  }

  Finder sheetButton(String label) => find.descendant(
    of: find.byKey(const Key('editor-tools-sheet')),
    matching: find.byTooltip(label),
  );

  Future<void> tapInSheet(WidgetTester tester, String label) async {
    final button = sheetButton(label);
    await tester.scrollUntilVisible(
      button,
      100,
      scrollable: find.descendant(
        of: find.byKey(const Key('editor-tools-sheet')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('nút Bảng cũ mở bộ chọn và chèn bảng 3×2 mặc định', (t) async {
    await pumpEditor(t, 'abc');
    editor(t).selection = const TextSelection.collapsed(offset: 3);
    await openSheet(t);
    await tapInSheet(t, l.toolbarItemTable);

    expect(find.byKey(const Key('table-picker')), findsOneWidget);
    await t.tap(find.byKey(const Key('table-insert')));
    await t.pumpAndSettle();

    expect(
      editor(t).text,
      'abc\n\n| Cột 1 | Cột 2 | Cột 3 |\n| --- | --- | --- |\n|  |  |  |\n|  |  |  |',
    );
  });

  testWidgets('bộ chọn bảng đổi được số cột và hàng', (t) async {
    await pumpEditor(t, '');
    await openSheet(t);
    await tapInSheet(t, l.toolbarItemTable);
    await t.tap(find.byKey(const Key('table-columns-dec')));
    await t.tap(find.byKey(const Key('table-rows-inc')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('table-insert')));
    await t.pumpAndSettle();

    expect(editor(t).text.split('\n').first, '| Cột 1 | Cột 2 |');
    expect(editor(t).text.split('\n').length, 2 + 3);
  });

  testWidgets(
    'Khối code chọn dart thì chèn ```dart và con trỏ nằm trong khối',
    (t) async {
      await pumpEditor(t, '');
      await openSheet(t);
      await tapInSheet(t, l.toolbarItemCodeBlock);
      await t.tap(find.byKey(const Key('code-lang-dart')));
      await t.pumpAndSettle();

      expect(editor(t).text, '```dart\n\n```');
      expect(editor(t).selection, const TextSelection.collapsed(offset: 8));
    },
  );

  testWidgets('chèn ngày giờ theo dạng yyyy-MM-dd HH:mm', (t) async {
    await pumpEditor(t, '');
    await openSheet(t);
    await tapInSheet(t, l.editorToolDateTime);

    expect(
      RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$').hasMatch(editor(t).text),
      isTrue,
      reason: editor(t).text,
    );
  });

  testWidgets('hủy bộ chọn thì văn bản không đổi', (t) async {
    await pumpEditor(t, 'abc');
    await openSheet(t);
    await tapInSheet(t, l.toolbarItemTable);
    await t.tap(find.text(l.commonCancel));
    await t.pumpAndSettle();
    expect(editor(t).text, 'abc');

    await openSheet(t);
    await tapInSheet(t, l.toolbarItemCodeBlock);
    await t.tapAt(const Offset(10, 10)); // chạm nền ngoài bảng chọn
    await t.pumpAndSettle();
    expect(editor(t).text, 'abc');
  });

  testWidgets('ký tự: hàng chip trong bảng chèn tại con trỏ và bảng giữ mở', (
    t,
  ) async {
    await pumpEditor(t, 'ab');
    editor(t).selection = const TextSelection.collapsed(offset: 1);
    await openSheet(t);
    final chip = find.byKey(const Key('symbol-{'));
    await t.scrollUntilVisible(
      chip,
      100,
      scrollable: find.descendant(
        of: find.byKey(const Key('editor-tools-sheet')),
        matching: find.byType(Scrollable),
      ),
    );
    await t.ensureVisible(chip);
    await t.pumpAndSettle();
    await t.tap(chip);
    await t.pumpAndSettle();

    expect(editor(t).text, 'a{b');
    expect(find.byKey(const Key('editor-tools-sheet')), findsOneWidget);
  });

  testWidgets('mẫu: chọn Nhật ký chèn nội dung tiếng Việt', (t) async {
    await pumpEditor(t, '');
    await openSheet(t);
    await tapInSheet(t, l.editorToolTemplate);
    await t.tap(find.byKey(const Key('template-journal')));
    await t.pumpAndSettle();

    expect(editor(t).text, startsWith('## Nhật ký'));
  });

  testWidgets('link tới note: chọn note khác chèn [Tiêu đề](ten-file.md)', (
    t,
  ) async {
    final b = repo.seed(fileName: 'note-b.md', content: 'B');
    repo.notes[b.filePath] = b.copyWith(title: 'Note [B]');
    await pumpEditor(t, 'x ');
    editor(t).selection = const TextSelection.collapsed(offset: 2);
    await openSheet(t);
    await tapInSheet(t, l.editorToolNoteLink);

    // Note đang mở không nằm trong danh sách chọn.
    expect(find.byKey(const Key('note-pick-/memory/ghi-chu.md')), findsNothing);
    await t.tap(find.byKey(const Key('note-pick-/memory/note-b.md')));
    await t.pumpAndSettle();

    expect(editor(t).text, r'x [Note \[B\]](note-b.md)');
  });
}
