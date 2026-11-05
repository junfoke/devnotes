// Nhóm Xem nhanh: mục lục và thống kê.
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

  Future<void> tapInSheet(WidgetTester tester, String label) async {
    final button = find.descendant(
      of: find.byKey(const Key('editor-tools-sheet')),
      matching: find.byTooltip(label),
    );
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

  testWidgets('mục lục liệt kê tiêu đề, bấm thì con trỏ nhảy tới đó', (
    t,
  ) async {
    const text = '# A\nnội dung\n## B\nthêm';
    await pumpEditor(t, text);
    await openSheet(t);
    await tapInSheet(t, l.editorToolOutline);

    expect(find.byKey(const Key('outline-picker')), findsOneWidget);
    expect(find.byKey(const Key('outline-0')), findsOneWidget);
    await t.tap(find.byKey(const Key('outline-1')));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('outline-picker')), findsNothing);
    expect(
      editor(t).selection,
      TextSelection.collapsed(offset: text.indexOf('## B')),
    );
  });

  testWidgets('note không có tiêu đề thì mục lục báo trống', (t) async {
    await pumpEditor(t, 'chỉ có chữ thường');
    await openSheet(t);
    await tapInSheet(t, l.editorToolOutline);

    expect(find.byKey(const Key('outline-empty')), findsOneWidget);
    expect(find.text(l.outlineEmpty), findsOneWidget);
  });

  testWidgets('bảng hiện số từ và thời gian đọc', (t) async {
    await pumpEditor(t, 'một hai ba');
    await openSheet(t);
    final line = find.text(l.editorStatsLine(3, 10, 1));
    await t.scrollUntilVisible(
      line,
      100,
      scrollable: find.descendant(
        of: find.byKey(const Key('editor-tools-sheet')),
        matching: find.byType(Scrollable),
      ),
    );

    expect(line, findsOneWidget);
  });
}
