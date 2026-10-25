// Note đang mở trong editor mà bị thay đổi từ bên ngoài (sync kéo bản mới về,
// app khác sửa file) thì editor KHÔNG được ghi đè im lặng bản mới đó.
//
// Quyết định: DECISIONS.md — "Editor không ghi đè thay đổi từ bên ngoài"
// (2026-10-25). Trước đây autosave luôn ghi nội dung đang hiện — bản sửa trên
// máy khác vừa kéo về bị xóa mất mà không có conflict nào.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
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
    note = repo.seed(fileName: 'ghi-chu.md', content: 'ban goc');
    container = ProviderContainer(overrides: [
      noteFileRepositoryProvider.overrideWith((ref) async => repo),
    ]);
  });

  tearDown(() => container.dispose());

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: EditorScreen(filePath: note.filePath),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Máy khác sửa note, sync kéo về trong lúc editor vẫn đang mở.
  void changedOutside(String content) {
    repo.notes[note.filePath] = note.copyWith(content: content);
  }

  Future<void> typeAndWaitAutosave(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('file đổi từ bên ngoài thì autosave không ghi đè, hỏi user',
      (tester) async {
    await pumpEditor(tester);
    changedOutside('ban moi tu laptop');

    await typeAndWaitAutosave(tester, 'ban dang sua');

    expect(repo.notes[note.filePath]!.content, 'ban moi tu laptop');
    expect(find.text('Ghi chú đã thay đổi bên ngoài'), findsOneWidget);
    expect(container.read(saveStatusProvider), SaveStatus.unsaved);
  });

  testWidgets('chọn tải bản mới thì editor hiện bản mới, không ghi gì',
      (tester) async {
    await pumpEditor(tester);
    changedOutside('ban moi tu laptop');
    await typeAndWaitAutosave(tester, 'ban dang sua');

    await tester.tap(find.text('Tải bản mới'));
    await tester.pumpAndSettle();

    expect(find.text('ban moi tu laptop'), findsOneWidget);
    expect(repo.notes[note.filePath]!.content, 'ban moi tu laptop');
    expect(container.read(saveStatusProvider), SaveStatus.saved);
  });

  testWidgets('chọn giữ bản của tôi thì lưu thành note mới, bản kia nguyên vẹn',
      (tester) async {
    await pumpEditor(tester);
    changedOutside('ban moi tu laptop');
    await typeAndWaitAutosave(tester, 'ban dang sua');

    await tester.tap(find.text('Lưu bản của tôi thành note mới'));
    await tester.pumpAndSettle();

    expect(repo.notes[note.filePath]!.content, 'ban moi tu laptop');
    final copies = repo.notes.values
        .where((n) => n.filePath != note.filePath)
        .toList();
    expect(copies, hasLength(1));
    expect(copies.single.content, 'ban dang sua');
  });

  testWidgets('không ai đổi file thì autosave ghi bình thường', (tester) async {
    await pumpEditor(tester);

    await typeAndWaitAutosave(tester, 'ban dang sua');

    expect(repo.notes[note.filePath]!.content, 'ban dang sua');
    expect(find.text('Ghi chú đã thay đổi bên ngoài'), findsNothing);
  });

  testWidgets('lưu nhiều lần liên tiếp không bị coi là thay đổi bên ngoài',
      (tester) async {
    await pumpEditor(tester);

    await typeAndWaitAutosave(tester, 'lan 1');
    await typeAndWaitAutosave(tester, 'lan 2');

    expect(repo.notes[note.filePath]!.content, 'lan 2');
    expect(find.text('Ghi chú đã thay đổi bên ngoài'), findsNothing);
  });

  testWidgets('editor mở thì đếm là đang có editor (để hoãn sync tự động)',
      (tester) async {
    await pumpEditor(tester);
    expect(container.read(openEditorCountProvider), 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(container.read(openEditorCountProvider), 0);
  });

  // Bug: note được đọc qua provider có cache không tự hủy — sync kéo bản mới
  // về rồi mở lại note vẫn thấy nội dung cũ trong bộ nhớ.
  testWidgets('đóng rồi mở lại note thì thấy nội dung mới nhất trên đĩa',
      (tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(
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
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('ban goc'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    changedOutside('ban moi sau khi sync');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('ban moi sau khi sync'), findsOneWidget);
  });
}
