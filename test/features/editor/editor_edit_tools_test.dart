// Nhóm Sửa trong bảng công cụ: đưa dòng lên/xuống, nhân đôi/xóa dòng, thanh
// tìm & thay thế. Mọi thay đổi đi qua controller của editor nên tự lưu và lớp
// chặn ghi đè thay đổi bên ngoài vẫn bắt được.
//
// Kế hoạch: docs/superpowers/plans/2026-10-25-editor-tools.md, Task 6.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/editor/presentation/widgets/find_replace_bar.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
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

  Future<NoteFile> pumpEditor(WidgetTester tester, String content) async {
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
    // Lịch sử hoàn tác ghi nhận theo nhịp 500ms — cho qua nhịp đầu.
    await tester.pump(const Duration(seconds: 1));
    return note;
  }

  TextEditingController editor(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!;

  /// Mở bảng ⋯ rồi bấm công cụ theo nhãn.
  Future<void> runFromSheet(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const Key('editor-tools-button')));
    await tester.pumpAndSettle();
    final sheet = find.byKey(const Key('editor-tools-sheet'));
    final button = find.descendant(of: sheet, matching: find.byTooltip(label));
    await tester.scrollUntilVisible(
      button,
      100,
      scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)),
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> flushAutosave(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('đưa dòng xuống làm note thành chưa lưu rồi được tự lưu', (
    t,
  ) async {
    final note = await pumpEditor(t, 'a\nb');
    editor(t).selection = const TextSelection.collapsed(offset: 0);

    await runFromSheet(t, l.editorToolMoveDown);
    expect(editor(t).text, 'b\na');
    expect(container.read(saveStatusProvider), SaveStatus.unsaved);

    await flushAutosave(t);
    expect(repo.notes[note.filePath]!.content, 'b\na');
  });

  testWidgets('đưa dòng lên, nhân đôi và xóa dòng sửa đúng dòng có con trỏ', (
    t,
  ) async {
    await pumpEditor(t, 'a\nb\nc');
    editor(t).selection = const TextSelection.collapsed(offset: 2); // dòng b

    await runFromSheet(t, l.editorToolMoveUp);
    expect(editor(t).text, 'b\na\nc');
    await runFromSheet(t, l.editorToolDuplicateLine);
    expect(editor(t).text, 'b\nb\na\nc');
    await runFromSheet(t, l.editorToolDeleteLine);
    expect(editor(t).text, 'b\na\nc');
    await flushAutosave(t);
  });

  testWidgets('tìm hiện số kết quả và chọn kết quả đầu tiên', (t) async {
    await pumpEditor(t, 'x y x');
    await runFromSheet(t, l.editorToolFindReplace);
    expect(find.byType(FindReplaceBar), findsOneWidget);
    // Bảng đã đóng, chữ của note vẫn thấy.
    expect(find.byKey(const Key('editor-tools-sheet')), findsNothing);

    await t.enterText(find.byKey(const Key('find-query')), 'x');
    await t.pump();

    expect(find.text('1/2'), findsOneWidget);
    expect(editor(t).selection.start, 0);
    expect(editor(t).selection.end, 1);

    await t.tap(find.byTooltip(l.findNext));
    await t.pump();
    expect(find.text('2/2'), findsOneWidget);
    expect(editor(t).selection.start, 4);
    expect(editor(t).selection.end, 5);

    await t.tap(find.byTooltip(l.findClose));
    await t.pumpAndSettle();
    expect(find.byType(FindReplaceBar), findsNothing);
  });

  testWidgets('thay thay chỗ đang chọn rồi sang kết quả kế tiếp', (t) async {
    await pumpEditor(t, 'x y x');
    await runFromSheet(t, l.editorToolFindReplace);
    await t.enterText(find.byKey(const Key('find-query')), 'x');
    await t.enterText(find.byKey(const Key('find-replacement')), 'zz');
    await t.pump();

    await t.tap(find.text(l.findReplaceOne));
    await t.pump();
    expect(editor(t).text, 'zz y x');
    expect(find.text('1/1'), findsOneWidget);
    expect(editor(t).selection.start, 5);
    await flushAutosave(t);
  });

  testWidgets('thay hết thay mọi chỗ và hoàn tác được một lần', (t) async {
    await pumpEditor(t, 'x y x');
    await runFromSheet(t, l.editorToolFindReplace);
    await t.enterText(find.byKey(const Key('find-query')), 'x');
    await t.enterText(find.byKey(const Key('find-replacement')), 'zz');
    await t.pump(const Duration(seconds: 1));

    await t.tap(find.text(l.findReplaceAll));
    await t.pump();
    expect(editor(t).text, 'zz y zz');
    expect(find.text('0/0'), findsOneWidget);
    await t.pump(const Duration(seconds: 1));

    await t.tap(find.byTooltip(l.editorToolUndo));
    await t.pump();
    expect(editor(t).text, 'x y x');
    await flushAutosave(t);
  });

  testWidgets(
    'đang có thay đổi bên ngoài thì lệnh sửa vẫn bị chặn ghi đè như gõ phím',
    (t) async {
      final note = await pumpEditor(t, 'ban goc');
      repo.notes[note.filePath] = note.copyWith(content: 'ban moi tu laptop');

      await runFromSheet(t, l.editorToolDuplicateLine);
      expect(editor(t).text, 'ban goc\nban goc');
      await flushAutosave(t);

      expect(find.text(l.externalChangeTitle), findsOneWidget);
      expect(repo.notes[note.filePath]!.content, 'ban moi tu laptop');
    },
  );
}
