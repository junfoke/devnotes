import 'dart:io';

import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/features/git_sync/domain/conflict_parser.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class SyncResult {
  final bool success;
  final int filesChanged;
  final List<String> conflicts;
  final String? error;

  const SyncResult({
    required this.success,
    this.filesChanged = 0,
    this.conflicts = const [],
    this.error,
  });
}

class SyncService {
  final GitClient gitClient;
  final MetadataDatabase metadataDb;

  /// Đọc nội dung file (tách ra để test không cần đĩa thật).
  final Future<String> Function(String path) readFile;

  SyncService({
    required this.gitClient,
    required this.metadataDb,
    Future<String> Function(String path)? readFile,
  }) : readFile = readFile ?? ((path) => File(path).readAsString());

  /// Xử lý các file git còn đánh dấu conflict từ lần trước. File đã hết dấu
  /// conflict (giải quyết qua màn hình hoặc sửa tay) → đánh dấu đã giải quyết.
  /// Trả về các file **còn** dấu conflict.
  ///
  /// Xem DECISIONS.md, "Không bao giờ commit file còn dấu conflict"
  /// (2026-10-25): `commitAll` stage mọi `*.md`, nên nếu không chặn ở đây thì
  /// file còn `<<<<<<<` sẽ bị commit và đẩy lên remote.
  Future<List<String>> _settleConflicts() async {
    final remaining = <String>[];
    for (final file in await gitClient.conflictedFiles()) {
      String content;
      try {
        content = await readFile(file);
      } catch (_) {
        // File đã bị xóa → coi như user chọn xóa; git add sẽ ghi nhận.
        content = '';
      }
      if (ConflictParser.hasConflicts(content)) {
        remaining.add(file);
      } else {
        await gitClient.markResolved(file);
      }
    }
    return remaining;
  }

  Future<SyncResult> sync(GitConfig config) async {
    // Bước đang chạy — để lịch sử ghi đúng bước nào lỗi.
    var step = SyncAction.commit;
    try {
      // 0. Conflict còn dở từ lần trước thì phải giải quyết hết rồi mới sync.
      final unresolved = await _settleConflicts();
      if (unresolved.isNotEmpty) {
        metadataDb.addSyncLogEntry(
          action: SyncAction.pull,
          filesChanged: 0,
          success: false,
          // Bản ghi lịch sử, không phải chữ giao diện: giữ tiếng Anh kỹ
          // thuật, trung lập với ngôn ngữ đang chọn.
          errorMessage: '${unresolved.length} unresolved conflicts',
        );
        return SyncResult(success: false, conflicts: unresolved);
      }

      // 1. Commit thay đổi trên máy TRƯỚC khi pull. Xem DECISIONS.md, "Sync
      //    theo thứ tự commit → pull → push" (2026-10-25): pull khi còn file
      //    sửa dở thì fast-forward có thể bị chặn giữa chừng và lần commit sau
      //    lùi mất thay đổi từ remote; commit trước thì hai phía cùng sửa một
      //    note luôn thành conflict để user chọn, không bao giờ đè im lặng.
      //    Đang dở merge (vừa giải quyết conflict) thì đây là merge commit.
      step = SyncAction.commit;
      final hasChanges = await gitClient.hasChanges();
      if (hasChanges) {
        final timestamp = DateTime.now().toUtc().toIso8601String();
        await gitClient.commitAll('DevNotes sync $timestamp');
      }

      // 2. Pull — conflict thì dừng, chưa đẩy gì lên.
      step = SyncAction.pull;
      final pullResult = await gitClient.pull(
        username: config.username,
        password: config.pat,
      );

      if (pullResult.hasConflicts) {
        for (final file in pullResult.conflicts) {
          metadataDb.upsertSyncStatus(file, SyncStatus.conflict);
        }
        metadataDb.addSyncLogEntry(
          action: SyncAction.pull,
          filesChanged: pullResult.filesChanged,
          success: false,
          errorMessage: '${pullResult.conflicts.length} conflicts',
        );
        return SyncResult(
          success: false,
          filesChanged: pullResult.filesChanged,
          conflicts: pullResult.conflicts,
        );
      }

      // 3. Luôn push, kể cả khi không có thay đổi mới: commit của một lần push
      //    lỗi trước đó (mất mạng…) phải được đẩy lên ở lần sync kế tiếp.
      //    Remote đã đủ thì push không làm gì.
      step = SyncAction.push;
      await gitClient.push(
        username: config.username,
        password: config.pat,
      );

      final totalChanged = pullResult.filesChanged + (hasChanges ? 1 : 0);
      metadataDb.addSyncLogEntry(
        action: hasChanges ? SyncAction.push : SyncAction.pull,
        filesChanged: totalChanged,
        success: true,
      );

      return SyncResult(success: true, filesChanged: totalChanged);
    } catch (e) {
      metadataDb.addSyncLogEntry(
        action: step,
        filesChanged: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return SyncResult(success: false, error: e.toString());
    }
  }
}
