// Đổi tên note B (tên file đổi theo) thì mọi link tới B trong các note khác
// được sửa sang tên file mới. Đây là thao tác ghi vào NHIỀU file của user —
// xem DECISIONS.md, "Link giữa các note và tự sửa link khi đổi tên"
// (2026-10-25).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/editor/presentation/widgets/markdown_preview.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/l10n/app_localizations.dart';
import 'package:devnotes/l10n/app_localizations_vi.dart';

import '../editor/in_memory_note_repository.dart';

void main() {
  group('NoteActions.rename sửa link (repo trong bộ nhớ)', () {
    late InMemoryNoteRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = InMemoryNoteRepository();
      container = ProviderContainer(
        overrides: [
          noteFileRepositoryProvider.overrideWith((ref) async => repo),
        ],
      );
    });

    tearDown(() => container.dispose());

    NoteActions actions() => container.read(noteActionsProvider);
    String content(String fileName) =>
        repo.notes['${repo.workspacePath}/$fileName']!.content;

    test('đổi tên B thì link tới B trong A được sửa, note không liên quan giữ '
        'nguyên', () async {
      repo.seed(fileName: 'a.md', content: 'Xem [B](./b.md#muc) và b.md');
      final b = repo.seed(fileName: 'b.md', content: 'Tôi là B');
      repo.seed(fileName: 'c.md', content: 'Không link [D](d.md)');

      final result = await actions().rename(b.filePath, 'Moi');

      expect(result.note.filePath, '${repo.workspacePath}/moi.md');
      expect(result.failedFiles, isEmpty);
      expect(content('a.md'), 'Xem [B](./moi.md#muc) và b.md');
      expect(content('c.md'), 'Không link [D](d.md)');
      expect(content('moi.md'), 'Tôi là B');
      // Chỉ ghi note thật sự đổi nội dung — không ghi thừa (nhiễu sync).
      expect(repo.savedPaths, ['${repo.workspacePath}/a.md']);
    });

    test('note không đọc được thì bỏ qua và nằm trong failedFiles, các note '
        'khác vẫn được sửa', () async {
      final a = repo.seed(fileName: 'a.md', content: '[B](b.md)');
      final b = repo.seed(fileName: 'b.md', content: 'B');
      repo.seed(fileName: 'c.md', content: '[B](b.md)');
      repo.unreadable.add(a.filePath);

      final result = await actions().rename(b.filePath, 'Moi');

      expect(result.failedFiles, [a.filePath]);
      expect(content('a.md'), '[B](b.md)');
      expect(content('c.md'), '[B](moi.md)');
    });

    test('note ghi lỗi nằm trong failedFiles, vòng lặp đi tiếp', () async {
      final a = repo.seed(fileName: 'a.md', content: '[B](b.md)');
      final b = repo.seed(fileName: 'b.md', content: 'B');
      repo.seed(fileName: 'c.md', content: '[B](b.md)');
      repo.unwritable.add(a.filePath);

      final result = await actions().rename(b.filePath, 'Moi');

      expect(result.failedFiles, [a.filePath]);
      expect(content('a.md'), '[B](b.md)');
      expect(content('c.md'), '[B](moi.md)');
    });

    test('đổi tên lỗi thì không note nào bị đụng', () async {
      repo.seed(fileName: 'a.md', content: '[B](b.md)');
      final b = repo.seed(fileName: 'b.md', content: 'B');
      repo.failOnRename = true;

      await expectLater(actions().rename(b.filePath, 'Moi'), throwsA(anything));

      expect(content('a.md'), '[B](b.md)');
      expect(repo.savedPaths, isEmpty);
    });

    test('link tới chính nó trong note vừa đổi tên cũng được sửa', () async {
      final b = repo.seed(fileName: 'b.md', content: '[Đầu trang](b.md#top)');

      final result = await actions().rename(b.filePath, 'Moi');

      expect(result.failedFiles, isEmpty);
      expect(content('moi.md'), '[Đầu trang](moi.md#top)');
    });

    test('tên file không đổi thì không duyệt note nào', () async {
      final b = repo.seed(fileName: 'b.md', content: 'B');
      repo.seed(fileName: 'a.md', content: '[B](b.md)');
      // Nếu có duyệt, mọi lần đọc đều lỗi → failedFiles khác rỗng.
      repo.failOnRead = true;

      final result = await actions().rename(b.filePath, 'b');

      expect(result.failedFiles, isEmpty);
      expect(repo.savedPaths, isEmpty);
    });
  });

  group('NoteActions.rename sửa link (file thật trong thư mục tạm)', () {
    late Directory dir;
    late NoteFileRepository repo;
    late ProviderContainer container;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('devnotes_links_');
      repo = NoteFileRepository(workspacePath: dir.path);
      container = ProviderContainer(
        overrides: [
          noteFileRepositoryProvider.overrideWith((ref) async => repo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      dir.deleteSync(recursive: true);
    });

    test(
      'đổi tên trên đĩa sửa link, file không đọc được nằm trong failedFiles',
      () async {
        final a = await repo.createNote(title: 'A', tags: const []);
        await repo.saveNote(a.copyWith(content: 'Xem [B](b.md).'));
        final b = await repo.createNote(title: 'B', tags: const []);
        // File không phải UTF-8 hợp lệ — đọc lỗi.
        final broken = File(p.join(dir.path, 'hong.md'))
          ..writeAsBytesSync([0xff, 0xfe, 0xfd]);

        final result = await container
            .read(noteActionsProvider)
            .rename(b.filePath, 'B mới');

        expect(p.basename(result.note.filePath), 'b-moi.md');
        expect(result.failedFiles, [broken.path]);
        expect((await repo.readNote(a.filePath)).content, 'Xem [B](b-moi.md).');
        expect(File(b.filePath).existsSync(), isFalse);
      },
    );
  });

  group('mở link note từ preview', () {
    late InMemoryNoteRepository repo;
    late ProviderContainer container;
    final l = AppLocalizationsVi();

    setUp(() {
      SharedPreferences.setMockInitialValues({'tooltip_editor': true});
      repo = InMemoryNoteRepository();
      container = ProviderContainer(
        overrides: [
          noteFileRepositoryProvider.overrideWith((ref) async => repo),
        ],
      );
    });

    tearDown(() => container.dispose());

    Future<void> pumpRouter(WidgetTester t, String filePath) async {
      final router = GoRouter(
        initialLocation: '/editor/${Uri.encodeComponent(filePath)}',
        routes: [
          GoRoute(
            path: '/editor/:filePath',
            builder: (_, state) => EditorScreen(
              filePath: Uri.decodeComponent(state.pathParameters['filePath']!),
            ),
          ),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            theme: AppTheme.light(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 1));
    }

    Future<void> showPreview(WidgetTester t) async {
      // Kéo ngang trên TextField không chuyển trang — nhảy thẳng sang preview.
      t.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
      await t.pumpAndSettle();
    }

    void tapLink(WidgetTester t, String href) {
      final md = t.widget<MarkdownPreview>(find.byType(MarkdownPreview));
      expect(md.onOpenNote, isNotNull);
      md.onOpenNote!(href);
    }

    testWidgets('bấm link note trong preview mở note đó trong editor', (
      t,
    ) async {
      final a = repo.seed(fileName: 'a.md', content: '[Sang B](b.md)');
      final b = repo.seed(fileName: 'b.md', content: 'Nội dung B');
      await pumpRouter(t, a.filePath);

      // Chữ vừa gõ chưa kịp autosave không được mất khi rời sang note khác.
      final field = t.widget<TextField>(find.byType(TextField).first);
      field.controller!.value = const TextEditingValue(
        text: '[Sang B](b.md) thêm',
        selection: TextSelection.collapsed(offset: 19),
      );
      await t.pump();
      await showPreview(t);
      tapLink(t, 'b.md');
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 1));

      expect(repo.notes[a.filePath]!.content, '[Sang B](b.md) thêm');
      final screens = t.widgetList<EditorScreen>(
        find.byType(EditorScreen, skipOffstage: false),
      );
      expect(screens.last.filePath, b.filePath);
      expect(find.text('Nội dung B'), findsOneWidget);
    });

    testWidgets('link tới note không tồn tại báo "Không tìm thấy note"', (
      t,
    ) async {
      final a = repo.seed(fileName: 'a.md', content: '[X](khong-co.md)');
      await pumpRouter(t, a.filePath);
      await showPreview(t);

      tapLink(t, 'khong-co.md');
      await t.pumpAndSettle();

      expect(find.text(l.noteNotFound('khong-co.md')), findsOneWidget);
      expect(find.byType(EditorScreen), findsOneWidget);
    });
  });
}
