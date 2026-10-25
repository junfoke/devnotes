// Menu ⋮ trong editor: Chia sẻ / Thông tin / Xóa (B-06).
//
// Luật quan trọng: xóa note ngay trong editor thì autosave đang chờ KHÔNG được
// ghi lại file vừa xóa — nếu không note "sống lại" sau 3 giây.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';

import 'in_memory_note_repository.dart';

void main() {
  late InMemoryNoteRepository repo;
  late NoteFile note;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({'tooltip_editor': true});
    repo = InMemoryNoteRepository();
    note = repo.seed(fileName: 'ghi-chu.md', content: 'mot hai ba');
    container = ProviderContainer(overrides: [
      noteFileRepositoryProvider.overrideWith((ref) async => repo),
    ]);
  });

  tearDown(() => container.dispose());

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EditorScreen(filePath: note.filePath),
                )),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> openMenuItem(WidgetTester tester, String label) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('menu ⋮ có đủ Chia sẻ, Thông tin, Xóa', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Chia sẻ'), findsOneWidget);
    expect(find.text('Thông tin'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
  });

  testWidgets('xóa note thì rời editor và note biến mất', (tester) async {
    await pumpEditor(tester);

    await openMenuItem(tester, 'Xóa');
    await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
    await tester.pumpAndSettle();

    expect(repo.notes.containsKey(note.filePath), isFalse);
    expect(find.byType(EditorScreen), findsNothing);
  });

  testWidgets('xóa khi đang có autosave chờ thì note không sống lại',
      (tester) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'sua do');
    await tester.pump();

    await openMenuItem(tester, 'Xóa');
    await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
    await tester.pumpAndSettle();

    // Qua mốc debounce 3 giây của autosave.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(repo.notes.containsKey(note.filePath), isFalse);
  });

  testWidgets('hủy xác nhận xóa thì note còn nguyên, vẫn ở editor',
      (tester) async {
    await pumpEditor(tester);

    await openMenuItem(tester, 'Xóa');
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(repo.notes.containsKey(note.filePath), isTrue);
    expect(find.byType(EditorScreen), findsOneWidget);
  });

  testWidgets('Thông tin hiện tên file và số từ', (tester) async {
    await pumpEditor(tester);

    await openMenuItem(tester, 'Thông tin');

    expect(find.textContaining('ghi-chu.md'), findsOneWidget);
    expect(find.textContaining('3 từ'), findsOneWidget);
  });
}
