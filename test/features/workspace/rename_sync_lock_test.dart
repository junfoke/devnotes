// Đổi tên + sửa link ghi vào NHIỀU file — không được chạy chồng với sync
// (pull có thể đang ghi đè chính những file đó, commit có thể chụp giữa
// chừng). Đổi tên giữ cùng khóa với sync (SyncRunner.exclusive).
// Xem DECISIONS.md, "Đổi tên note giữ khóa sync" (2026-10-26).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/git_sync/application/sync_controller.dart';
import 'package:devnotes/features/git_sync/application/sync_runner.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

import '../editor/in_memory_note_repository.dart';

/// Repository mà bước sửa link dừng ở [gate] — để kiểm tra trạng thái
/// "đang đổi tên dở".
class _GatedRepository extends InMemoryNoteRepository {
  final gate = Completer<void>();
  final reached = Completer<void>();

  @override
  Future<bool> rewriteBody(
    String filePath,
    String Function(String body) edit,
  ) async {
    if (!reached.isCompleted) reached.complete();
    await gate.future;
    return super.rewriteBody(filePath, edit);
  }
}

void main() {
  late _GatedRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _GatedRepository();
    container = ProviderContainer(
      overrides: [noteFileRepositoryProvider.overrideWith((ref) async => repo)],
    );
  });

  tearDown(() => container.dispose());

  test('đang đổi tên + sửa link thì sync (tự động hay bấm tay) không chạy',
      () async {
    repo.seed(fileName: 'a.md', content: '[B](b.md)');
    final b = repo.seed(fileName: 'b.md', content: 'B');

    final renaming =
        container.read(noteActionsProvider).rename(b.filePath, 'Moi');
    await repo.reached.future;

    final sync = container.read(syncControllerProvider);
    expect(sync.isRunning, isTrue);
    final outcome = await sync.sync(auto: true);
    expect(outcome.skipped, SyncSkipReason.alreadyRunning);

    repo.gate.complete();
    final result = await renaming;
    expect(result.failedFiles, isEmpty);
    expect(repo.notes['${repo.workspacePath}/a.md']!.content, '[B](moi.md)');
    // Xong thì nhả khóa.
    expect(sync.isRunning, isFalse);
  });

  test('đang sync thì đổi tên báo bận, không đụng file nào', () async {
    repo.gate.complete();
    repo.seed(fileName: 'a.md', content: '[B](b.md)');
    final b = repo.seed(fileName: 'b.md', content: 'B');
    final syncing = Completer<void>();
    final sync = container.read(syncControllerProvider);
    final held = sync.exclusive(() => syncing.future);

    await expectLater(
      container.read(noteActionsProvider).rename(b.filePath, 'Moi'),
      throwsA(isA<GitBusyException>()),
    );
    expect(repo.notes.containsKey(b.filePath), isTrue);
    expect(repo.savedPaths, isEmpty);

    syncing.complete();
    await held;
  });
}
