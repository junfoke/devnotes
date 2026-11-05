// Note đang mở trong editor mà bị thay đổi từ bên ngoài (sync kéo bản mới về,
// app khác sửa file) thì editor KHÔNG được ghi đè im lặng bản mới đó.
//
// Quyết định: DECISIONS.md — "Editor không ghi đè thay đổi từ bên ngoài"
// (2026-10-25). Trước đây autosave luôn ghi nội dung đang hiện — bản sửa trên
// máy khác vừa kéo về bị xóa mất mà không có conflict nào.
import 'dart:async';

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
import 'package:devnotes/l10n/app_localizations.dart';

void main() {
  group('editor nằm dưới editor khác', _backgroundEditorTests);
  group('lưu chồng nhau', _overlappingSaveTests);

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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
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

  // Bug (thấy trên emulator 26/10): file thật đọc lên bị cắt xuống dòng cuối,
  // nên note kết thúc bằng Enter bị báo nhầm "thay đổi bên ngoài" ở lần lưu
  // thứ hai — chọn "Tải bản mới" là mất chữ vừa gõ.
  testWidgets('note kết thúc bằng xuống dòng lưu lần hai không bị báo nhầm',
      (tester) async {
    repo.trimLikeDisk = true;
    await pumpEditor(tester);

    await typeAndWaitAutosave(tester, 'lan 1\n');
    await typeAndWaitAutosave(tester, 'lan 1\nlan 2\n');

    expect(find.text('Ghi chú đã thay đổi bên ngoài'), findsNothing);
    expect(repo.notes[note.filePath]!.content, 'lan 1\nlan 2');
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
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

// Editor A vẫn nằm dưới editor B (mở note qua link). Trạng thái lưu là một
// provider chung, nên trước đây A tưởng mình "chưa lưu" theo B: app xuống nền
// hay rời A đều ghi lại file của A (đổi updatedAt, nhiễu sync) và có thể bật
// hộp thoại "thay đổi bên ngoài" cho một note A không hề sửa.
void _backgroundEditorTests() {
  late InMemoryNoteRepository repo;
  late NoteFile a;
  late NoteFile b;
  late ProviderContainer container;
  final navKey = GlobalKey<NavigatorState>();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tooltip_editor': true});
    repo = InMemoryNoteRepository();
    a = repo.seed(fileName: 'a.md', content: 'note a');
    b = repo.seed(fileName: 'b.md', content: 'note b');
    container = ProviderContainer(overrides: [
      noteFileRepositoryProvider.overrideWith((ref) async => repo),
    ]);
  });

  tearDown(() => container.dispose());

  Future<void> pumpAThenB(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: navKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.light(),
        home: const Scaffold(body: Text('home')),
      ),
    ));
    navKey.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => EditorScreen(filePath: a.filePath)));
    await tester.pumpAndSettle();
    navKey.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => EditorScreen(filePath: b.filePath)));
    await tester.pumpAndSettle();
  }

  testWidgets('app xuống nền chỉ lưu editor có sửa, không ghi lại note bên dưới',
      (tester) async {
    await pumpAThenB(tester);
    await tester.enterText(find.byType(TextField).first, 'b da sua');
    await tester.pump();
    // Note A vừa được sync kéo bản mới về: A không sửa gì nên không được hỏi.
    repo.notes[a.filePath] = a.copyWith(content: 'a ban moi');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();

    expect(repo.savedPaths, [b.filePath]);
    expect(repo.notes[a.filePath]!.content, 'a ban moi');
    expect(find.text('Ghi chú đã thay đổi bên ngoài'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('rời editor không sửa gì thì không ghi file dù trạng thái chung '
      'đang "chưa lưu"', (tester) async {
    await pumpAThenB(tester);
    container.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    container.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(repo.savedPaths, isEmpty);
  });
}

/// Lần ghi dừng ở [gate] cho tới khi test mở — giả lập đĩa chậm.
class _SlowSaveRepository extends InMemoryNoteRepository {
  Completer<void>? gate;

  @override
  Future<void> saveNote(NoteFile note) async {
    final g = gate;
    if (g != null) await g.future;
    await super.saveNote(note);
  }
}

// App xuống nền đúng lúc autosave đang ghi dở: lần lưu thứ hai phải chờ lần
// đầu xong rồi mới xét — không thì nó đọc file vừa được ghi, so với bản cũ
// và hỏi nhầm "thay đổi bên ngoài".
void _overlappingSaveTests() {
  testWidgets('lưu chồng lúc đang ghi dở không hỏi nhầm, không ghi hai lần',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tooltip_editor': true});
    final repo = _SlowSaveRepository();
    final note = repo.seed(fileName: 'ghi-chu.md', content: 'ban goc');
    final container = ProviderContainer(overrides: [
      noteFileRepositoryProvider.overrideWith((ref) async => repo),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.light(),
        home: EditorScreen(filePath: note.filePath),
      ),
    ));
    await tester.pumpAndSettle();

    repo.gate = Completer<void>();
    await tester.enterText(find.byType(TextField).first, 'ban dang sua');
    await tester.pump(const Duration(seconds: 4)); // Autosave bắt đầu ghi.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    repo.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Ghi chú đã thay đổi bên ngoài'), findsNothing);
    expect(repo.savedPaths, [note.filePath]);
    expect(repo.notes[note.filePath]!.content, 'ban dang sua');
    expect(container.read(saveStatusProvider), SaveStatus.saved);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
