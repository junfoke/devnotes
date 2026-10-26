// Bảng "Công cụ soạn thảo" (nút ⋯): nhóm Hiển thị, chế độ Tùy chỉnh, và
// cách EditorScreen áp dụng cài đặt hiển thị.
//
// Kế hoạch: docs/superpowers/plans/2026-10-25-editor-tools.md, Task 5.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_app_bar.dart';
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
  late SharedPreferences prefs;
  var hasContainer = false;
  final l = AppLocalizationsVi();

  Future<void> setUpWith(Map<String, Object> values) async {
    // Tắt tooltip onboarding để nó không phủ lên màn hình trong test.
    SharedPreferences.setMockInitialValues({'tooltip_editor': true, ...values});
    prefs = await SharedPreferences.getInstance();
    if (hasContainer) container.dispose();
    hasContainer = true;
    repo = InMemoryNoteRepository();
    note = repo.seed(fileName: 'ghi-chu.md', content: 'noi dung');
    container = ProviderContainer(
      overrides: [
        noteFileRepositoryProvider.overrideWith((ref) async => repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  }

  setUp(() => setUpWith({'editor_font_size': 14.0}));
  tearDown(() {
    container.dispose();
    hasContainer = false;
  });

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

  TextField field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first);

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editor-tools-button')));
    await tester.pumpAndSettle();
  }

  /// Cuộn danh sách trong bảng tới [finder] rồi bấm.
  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.descendant(
        of: find.byKey(const Key('editor-tools-sheet')),
        matching: find.byType(Scrollable),
      ),
    );
    // Mục đã dựng sẵn trong vùng đệm (chưa lên màn hình) thì lệnh trên không
    // cuộn — kéo hẳn nó vào khung nhìn.
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10)); // Bấm vùng tối phía trên.
    await tester.pumpAndSettle();
  }

  testWidgets('bấm ⋯ mở bảng có đủ các nhóm', (tester) async {
    await pumpEditor(tester);
    await openSheet(tester);

    final sheet = find.byKey(const Key('editor-tools-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.text(l.editorToolGroupDisplay), findsOneWidget);
    for (final title in [
      l.editorToolGroupEdit,
      l.editorToolGroupInsert,
      l.editorToolGroupView,
      l.editorToolGroupFormat,
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        100,
        scrollable: find.descendant(
          of: sheet,
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('A+ trong bảng tăng cỡ chữ ô soạn ngay và lưu vào cài đặt', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(field(tester).style!.fontSize, 14);
    await openSheet(tester);

    await tester.tap(find.byTooltip(l.editorToolSizeUp));
    await tester.pumpAndSettle();

    // Bảng vẫn mở (điều khiển trực tiếp), ô soạn đổi ngay.
    expect(find.byKey(const Key('editor-tools-sheet')), findsOneWidget);
    expect(field(tester).style!.fontSize, 15);
    expect(prefs.getDouble('editor_font_size'), 15);
  });

  testWidgets('A− không xuống dưới 12', (tester) async {
    await setUpWith({'editor_font_size': 12.0});
    await pumpEditor(tester);
    await openSheet(tester);

    await tester.tap(find.byTooltip(l.editorToolSizeDown));
    await tester.pumpAndSettle();

    expect(field(tester).style!.fontSize, 12);
  });

  testWidgets('chọn Font hệ thống thì ô soạn không đặt fontFamily', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(field(tester).style!.fontFamily, 'JetBrainsMono');
    await openSheet(tester);

    await tester.tap(find.text(l.editorFontSystem));
    await tester.pumpAndSettle();

    expect(field(tester).style!.fontFamily, isNull);
    expect(prefs.getString('editor_font_family'), 'system');
  });

  testWidgets('chọn giãn dòng Thoáng thì ô soạn dùng hệ số 1.9', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(field(tester).style!.height, 1.6);
    await openSheet(tester);

    await tester.tap(find.text(l.lineHeightRelaxed));
    await tester.pumpAndSettle();

    expect(field(tester).style!.height, 1.9);
  });

  testWidgets('tắt tự xuống dòng thì dòng dài cuộn ngang', (tester) async {
    await pumpEditor(tester);
    final horizontalScroll = find.ancestor(
      of: find.byType(TextField),
      matching: find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
    );
    expect(horizontalScroll, findsNothing);

    await openSheet(tester);
    await tester.tap(find.widgetWithText(SwitchListTile, l.editorToolWordWrap));
    await tester.pumpAndSettle();
    await closeSheet(tester);

    expect(horizontalScroll, findsOneWidget);
    // Dòng dài không bị bẻ: ô soạn rộng hơn màn hình.
    await tester.enterText(find.byType(TextField).first, 'x' * 400);
    await tester.pumpAndSettle();
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      tester.getSize(find.byType(TextField)).width,
      greaterThan(screenWidth),
    );
    expect(prefs.getBool('editor_word_wrap'), isFalse);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('chế độ tập trung ẩn thanh tiêu đề, tắt lại từ bảng', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(find.byType(EditorAppBar), findsOneWidget);

    await openSheet(tester);
    final focusSwitch = find.widgetWithText(
      SwitchListTile,
      l.editorToolFocusMode,
    );
    await tester.tap(focusSwitch);
    await tester.pumpAndSettle();
    expect(find.byType(EditorAppBar), findsNothing);

    // Lối thoát: công tắc trong bảng ⋯ vẫn còn.
    await tester.tap(focusSwitch);
    await tester.pumpAndSettle();
    expect(find.byType(EditorAppBar), findsOneWidget);
  });

  testWidgets('chế độ tập trung: Back hệ thống vẫn lưu rồi mới rời', (
    tester,
  ) async {
    await setUpWith({'editor_focus_mode': true});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditorScreen(filePath: note.filePath),
                  ),
                ),
                child: const Text('mo'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('mo'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorAppBar), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'chu moi');
    await tester.pump();
    final handled = await tester.binding.handlePopRoute();
    expect(handled, isTrue);
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsNothing);
    expect(repo.notes[note.filePath]!.content, 'chu moi');
  });

  testWidgets('bật Sáng/Tối từ bảng khi đang theo hệ thống thì chuyển sang '
      'ngược với độ sáng hiện tại', (tester) async {
    await pumpEditor(tester);
    expect(container.read(themeProvider), ThemePreference.system);
    await openSheet(tester);

    await tester.tap(find.byTooltip(l.editorToolTheme));
    await tester.pumpAndSettle();

    // Màn hình đang sáng (AppTheme.light) → chuyển sang tối.
    expect(container.read(themeProvider), ThemePreference.dark);
  });

  testWidgets(
    'Tùy chỉnh: ghim "Ngày giờ" thì nó xuất hiện trên thanh công cụ',
    (tester) async {
      await pumpEditor(tester);
      expect(
        find.descendant(
          of: find.byType(EditorToolbar),
          matching: find.byTooltip(l.editorToolDateTime),
        ),
        findsNothing,
      );
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('tools-customize')));
      await tester.pumpAndSettle();

      await tapInSheet(tester, find.byKey(const Key('pin-date_time')));
      await closeSheet(tester);

      final toolbarScroll = find.descendant(
        of: find.byType(EditorToolbar),
        matching: find.byType(Scrollable),
      );
      final pinned = find.descendant(
        of: find.byType(EditorToolbar),
        matching: find.byTooltip(l.editorToolDateTime),
      );
      await tester.scrollUntilVisible(pinned, 100, scrollable: toolbarScroll);
      expect(pinned, findsOneWidget);
      // Ghim thêm vào cuối danh sách.
      expect(prefs.getStringList('editor_toolbar_items')!.last, 'date_time');
    },
  );

  testWidgets('Tùy chỉnh: ẩn "Mục lục" thì nó biến khỏi bảng nhưng vẫn được '
      'liệt kê để bật lại', (tester) async {
    await pumpEditor(tester);
    await openSheet(tester);
    final sheet = find.byKey(const Key('editor-tools-sheet'));
    final outlineButton = find.descendant(
      of: sheet,
      matching: find.byTooltip(l.editorToolOutline),
    );
    await tester.scrollUntilVisible(
      outlineButton,
      100,
      scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)),
    );
    expect(outlineButton, findsOneWidget);

    await tester.tap(find.byKey(const Key('tools-customize')));
    await tester.pumpAndSettle();
    await tapInSheet(tester, find.byKey(const Key('show-outline')));
    expect(prefs.getStringList('editor_hidden_tools'), ['outline']);

    // Chế độ Tùy chỉnh vẫn liệt kê mục bị ẩn để bật lại.
    expect(find.byKey(const Key('show-outline')), findsOneWidget);

    // Thoát Tùy chỉnh: mục đã biến khỏi bảng.
    await tester.tap(find.byKey(const Key('tools-customize')));
    await tester.pumpAndSettle();
    expect(outlineButton, findsNothing);
    // Ẩn khỏi bảng không đụng tới danh sách ghim.
    expect(
      prefs.getStringList('editor_toolbar_items') ?? const <String>[],
      isNot(contains('outline')),
    );
  });

  testWidgets('bật/tắt tự xuống dòng giữa chừng không mất lịch sử hoàn tác', (
    tester,
  ) async {
    await setUpWith({
      'editor_tools_migrated_v1': true,
      'editor_toolbar_items': ['undo', 'word_wrap'],
    });
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'noi dung them');
    await tester.pump(const Duration(seconds: 1));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    Future<void> tapPinned(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(EditorToolbar),
          matching: find.byTooltip(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await tapPinned(l.editorToolWordWrap); // Tắt.
    expect(prefs.getBool('editor_word_wrap'), isFalse);
    await tapPinned(l.editorToolWordWrap); // Bật lại.
    expect(prefs.getBool('editor_word_wrap'), isTrue);

    await tapPinned(l.editorToolUndo);
    expect(field(tester).controller!.text, 'noi dung');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('nút hiển thị ghim trên thanh công cụ cũng chạy (ruling R2)', (
    tester,
  ) async {
    await setUpWith({
      'editor_font_size': 24.0,
      'editor_tools_migrated_v1': true,
      'editor_toolbar_items': ['size_up', 'size_down', 'font', 'line_height'],
    });
    await pumpEditor(tester);
    Future<void> tapPinned(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(EditorToolbar),
          matching: find.byTooltip(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await tapPinned(l.editorToolSizeUp); // Đã 24: không vượt trần.
    expect(field(tester).style!.fontSize, 24);
    await tapPinned(l.editorToolSizeDown);
    expect(field(tester).style!.fontSize, 23);

    // Font: JetBrains Mono → Fira Code → hệ thống → JetBrains Mono.
    await tapPinned(l.editorToolFont);
    expect(field(tester).style!.fontFamily, 'FiraCode');
    await tapPinned(l.editorToolFont);
    expect(field(tester).style!.fontFamily, isNull);
    await tapPinned(l.editorToolFont);
    expect(field(tester).style!.fontFamily, 'JetBrainsMono');

    // Giãn dòng: Vừa → Thoáng → Gọn.
    await tapPinned(l.editorToolLineHeight);
    expect(field(tester).style!.height, 1.9);
    await tapPinned(l.editorToolLineHeight);
    expect(field(tester).style!.height, 1.35);
  });

  testWidgets('chuyển sang preview rồi quay lại vẫn hoàn tác được chữ vừa gõ', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'noi dung them');
    await tester.pump(const Duration(seconds: 1));
    // Ô đang có focus thì EditableText tự giữ trang sống — bỏ focus (bàn phím
    // đã đóng) mới là trường hợp trang soạn bị hủy.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    // Sang preview rồi về. Kéo ngang trên TextField bị ô nhập giành cử chỉ
    // nên chuyển trang thẳng bằng controller (giống editor_toolbar_test).
    final pageController = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    pageController.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(find.byType(EditorToolbar), findsNothing); // Đang ở preview.
    pageController.jumpToPage(0);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l.editorToolUndo));
    await tester.pump();
    expect(field(tester).controller!.text, 'noi dung');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
