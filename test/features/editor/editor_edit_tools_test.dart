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

  EditableTextState editableState(WidgetTester tester) =>
      tester.state<EditableTextState>(
        find.descendant(
          of: find.byType(TextField).first,
          matching: find.byType(EditableText),
        ),
      );

  /// Các đoạn chữ có màu nền (được tô) trong chữ ô soạn đang vẽ.
  List<TextSpan> highlightedSpans(WidgetTester tester) {
    final out = <TextSpan>[];
    editableState(tester).renderEditable.text!.visitChildren((span) {
      if (span is TextSpan && span.style?.backgroundColor != null) {
        out.add(span);
      }
      return true;
    });
    return out;
  }

  /// Focus vẫn ở ô tìm (không chuyển sang ô soạn).
  bool findFieldHasFocus(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('find-query')),
          matching: find.byType(EditableText),
        ),
      )
      .focusNode
      .hasFocus;

  ScrollPosition editorScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(TextField).first,
          matching: find.byType(Scrollable),
        ),
      )
      .position;

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

  // Bug (emulator 26/10): đang gõ trong ô soạn rồi mở Tìm và thay — autofocus
  // không có tác dụng vì ô soạn vẫn giữ focus, chữ gõ tiếp rơi vào note.
  testWidgets('mở tìm khi ô soạn đang focus thì ô tìm nhận focus', (t) async {
    await pumpEditor(t, 'x y x');
    await t.tap(find.byType(TextField).first);
    await t.pump();
    expect(editableState(t).widget.focusNode.hasFocus, isTrue);

    await runFromSheet(t, l.editorToolFindReplace);

    expect(findFieldHasFocus(t), isTrue);
  });

  // Ruling R8: ô tìm giữ focus nên vùng chọn của ô soạn không được tô — kết
  // quả phải được tô thẳng trong chữ của note, không thì user bấm "Thay" mà
  // không thấy chữ nào sẽ bị thay.
  testWidgets('kết quả được tô trong ô soạn, kết quả đang chọn tô đậm hơn; '
      'đóng thanh thì hết tô', (t) async {
    await pumpEditor(t, 'x y x');
    await runFromSheet(t, l.editorToolFindReplace);
    await t.enterText(find.byKey(const Key('find-query')), 'x');
    await t.pump();

    final spans = highlightedSpans(t);
    expect(spans.map((s) => s.text), ['x', 'x']);
    final current = spans[0].style!.backgroundColor;
    final other = spans[1].style!.backgroundColor;
    expect(current, isNotNull);
    expect(other, isNotNull);
    expect(current, isNot(other));
    // Ô tìm vẫn giữ focus, nội dung note không đổi.
    expect(findFieldHasFocus(t), isTrue);
    expect(editor(t).text, 'x y x');

    await t.tap(find.byTooltip(l.findNext));
    await t.pump();
    final after = highlightedSpans(t);
    expect(after[0].style!.backgroundColor, other);
    expect(after[1].style!.backgroundColor, current);

    await t.tap(find.byTooltip(l.findClose));
    await t.pumpAndSettle();
    expect(highlightedSpans(t), isEmpty);
    expect(container.read(saveStatusProvider), SaveStatus.saved);
  });

  testWidgets('chuyển tới kết quả ở cuối note dài thì ô soạn cuộn tới đó', (
    t,
  ) async {
    final lines = [for (var i = 0; i < 300; i++) 'dong $i', 'dich den'];
    await pumpEditor(t, lines.join('\n'));
    // Nạp xong con trỏ ở cuối — đưa về đầu để thấy việc cuộn.
    editorScroll(t).jumpTo(0);
    await t.pump();
    await runFromSheet(t, l.editorToolFindReplace);
    editorScroll(t).jumpTo(0);
    await t.pump();
    expect(editorScroll(t).pixels, 0);

    await t.enterText(find.byKey(const Key('find-query')), 'dich den');
    await t.pumpAndSettle();

    expect(editorScroll(t).pixels, greaterThan(0));
    // Kết quả nằm trong khung nhìn của ô soạn.
    final editable = editableState(t).renderEditable;
    final caret = editable.getLocalRectForCaret(
      TextPosition(offset: editor(t).text.indexOf('dich den')),
    );
    expect(caret.top, greaterThanOrEqualTo(0));
    // Sai số dưới 1px do chiều cao dòng lẻ.
    expect(caret.bottom, lessThanOrEqualTo(editable.size.height + 1));
    expect(findFieldHasFocus(t), isTrue);
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
