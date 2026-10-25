// Thanh công cụ editor: nút ⋯ cố định, hoàn tác/làm lại, thụt/lùi lề.
//
// Kế hoạch: docs/superpowers/plans/2026-10-25-editor-tools.md, Task 4.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_toolbar.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/l10n/app_localizations.dart';
import 'package:devnotes/l10n/app_localizations_vi.dart';

import 'in_memory_note_repository.dart';

void main() {
  late InMemoryNoteRepository repo;
  late NoteFile note;
  late ProviderContainer container;
  final l = AppLocalizationsVi();

  setUp(() {
    // Tắt tooltip onboarding để nó không phủ lên màn hình trong test.
    SharedPreferences.setMockInitialValues({'tooltip_editor': true});
    repo = InMemoryNoteRepository();
    note = repo.seed(fileName: 'ghi-chu.md', content: 'noi dung');
    container = ProviderContainer(
      overrides: [noteFileRepositoryProvider.overrideWith((ref) async => repo)],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpEditor(WidgetTester tester) async {
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
  }

  TextEditingController controllerOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!;

  /// Chuyển trang PageView (0: soạn, 1: preview). Kéo ngang trên TextField
  /// bị ô nhập giành cử chỉ nên dùng thẳng controller.
  Future<void> goToPage(WidgetTester tester, int page) async {
    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(page);
    await tester.pumpAndSettle();
  }

  /// Bấm nút ghim theo nhãn; cuộn thanh công cụ tới nút nếu nó khuất.
  Future<void> tapTool(
    WidgetTester tester,
    String label, {
    bool warnIfMissed = true,
  }) async {
    final button = find.byTooltip(label);
    await tester.scrollUntilVisible(
      button,
      100,
      scrollable: find.descendant(
        of: find.byType(EditorToolbar),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(button, warnIfMissed: warnIfMissed);
  }

  /// Chờ qua debounce tự lưu (3s) và để tác vụ ghi chạy xong.
  Future<void> flushAutosave(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('nút ⋯ luôn hiện ở thanh công cụ', (tester) async {
    await pumpEditor(tester);
    expect(find.byKey(const Key('editor-tools-button')), findsOneWidget);
    expect(find.byTooltip(l.editorToolsButton), findsOneWidget);
  });

  testWidgets('thụt lề từ thanh công cụ thêm 2 dấu cách và được tự lưu', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'a');
    await tester.pump();

    await tapTool(tester, l.editorToolIndent);
    await tester.pump();
    expect(controllerOf(tester).text, '  a');

    await flushAutosave(tester);
    expect(repo.notes[note.filePath]!.content, '  a');
  });

  testWidgets('lùi lề từ thanh công cụ bỏ 2 dấu cách đầu dòng', (tester) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, '  a');
    await tester.pump();

    await tapTool(tester, l.editorToolOutdent);
    await tester.pump();
    expect(controllerOf(tester).text, 'a');
    await flushAutosave(tester);
  });

  testWidgets('hoàn tác ngay sau khi mở note không xóa nội dung đã tải', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(controllerOf(tester).text, 'noi dung');

    await tapTool(tester, l.editorToolUndo);
    await tester.pump();

    expect(controllerOf(tester).text, 'noi dung');
  });

  testWidgets('gõ rồi hoàn tác thì về nội dung trước khi gõ, làm lại thì quay '
      'lại chữ vừa gõ', (tester) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'noi dung them');
    await tester.pump(const Duration(seconds: 1));

    await tapTool(tester, l.editorToolUndo);
    await tester.pump();
    expect(controllerOf(tester).text, 'noi dung');

    await tapTool(tester, l.editorToolRedo);
    await tester.pump();
    expect(controllerOf(tester).text, 'noi dung them');
    await flushAutosave(tester);
  });

  testWidgets('tải bản mới từ bên ngoài rồi hoàn tác không quay về bản cũ', (
    tester,
  ) async {
    await pumpEditor(tester);
    // File bị sửa ở nơi khác trong lúc đang gõ.
    repo.notes[note.filePath] = note.copyWith(content: 'ban moi tu laptop');
    await tester.enterText(find.byType(TextField).first, 'ban dang sua');
    await flushAutosave(tester);
    await tester.tap(find.text('Tải bản mới'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(controllerOf(tester).text, 'ban moi tu laptop');

    await tapTool(tester, l.editorToolUndo);
    await tester.pump();
    expect(controllerOf(tester).text, 'ban moi tu laptop');
  });

  testWidgets('đánh dấu checklist ở preview, gõ tiếp rồi hoàn tác thì ô vẫn '
      'được đánh dấu', (tester) async {
    note = repo.seed(fileName: 'ghi-chu.md', content: '- [ ] viec');
    await pumpEditor(tester);

    // Sang trang preview, đánh dấu ô, quay lại trang soạn.
    await goToPage(tester, 1);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump(const Duration(seconds: 1));
    await goToPage(tester, 0);
    expect(controllerOf(tester).text, '- [x] viec');
    // Ô soạn được dựng lại khi quay về trang 0 — chờ nhịp ghi lịch sử đầu.
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).first, '- [x] viec them');
    await tester.pump(const Duration(seconds: 1));

    await tapTool(tester, l.editorToolUndo);
    await tester.pump();
    expect(controllerOf(tester).text, contains('- [x]'));
    expect(controllerOf(tester).text, '- [x] viec');
    await flushAutosave(tester);
  });

  testWidgets(
    'note tải lỗi thì nút sửa văn bản bị vô hiệu, bấm không ném lỗi',
    (tester) async {
      repo.failOnRead = true;
      await pumpEditor(tester);

      final toolbar = tester.widget<EditorToolbar>(find.byType(EditorToolbar));
      expect(toolbar.enabled, isFalse);

      await tapTool(tester, l.editorToolIndent, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Nút ⋯ vẫn bấm được.
      expect(find.byKey(const Key('editor-tools-button')), findsOneWidget);
    },
  );
}
