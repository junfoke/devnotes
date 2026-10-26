// lib/features/workspace/application/workspace_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/features/editor/domain/note_links.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

final noteListProvider = FutureProvider<List<NoteFile>>((ref) async {
  final repo = await ref.watch(noteFileRepositoryProvider.future);
  return repo.listNotes();
});

final selectedCollectionProvider = StateProvider<String?>((ref) => null);

/// Tạo / đổi tên / xóa note. Mỗi lần gọi là một lần chạy thật.
///
/// Trước đây là các FutureProvider.family: Riverpod cache kết quả theo tham
/// số, nên xóa lại một note cùng đường dẫn (hay đổi tên A→B lần hai) chỉ trả
/// về kết quả cũ mà không chạm vào file.
class NoteActions {
  NoteActions(this._ref);

  final Ref _ref;

  Future<NoteFile> create({
    required String title,
    required List<String> tags,
  }) async {
    final repo = await _ref.read(noteFileRepositoryProvider.future);
    final note = await repo.createNote(title: title, tags: tags);
    _ref.invalidate(noteListProvider);
    return note;
  }

  /// Đổi tên note rồi sửa mọi link tới nó trong các note (kể cả chính nó).
  ///
  /// Đổi tên lỗi thì ném lỗi và không note nào khác bị đụng. Sau đó, note nào
  /// đọc hoặc ghi lỗi thì nằm trong `failedFiles` (đường dẫn) và vòng lặp đi
  /// tiếp. Xem DECISIONS.md, "Link giữa các note và tự sửa link khi đổi tên"
  /// (2026-10-25).
  Future<({NoteFile note, List<String> failedFiles})> rename(
    String filePath,
    String newTitle,
  ) async {
    final repo = await _ref.read(noteFileRepositoryProvider.future);
    final note = await repo.renameNote(filePath, newTitle);
    final from = p.basename(filePath);
    final to = p.basename(note.filePath);
    final failed = from == to
        ? const <String>[]
        : await _rewriteLinks(repo, from: from, to: to);
    _ref.invalidate(noteListProvider);
    return (note: note, failedFiles: failed);
  }

  Future<List<String>> _rewriteLinks(
    NoteFileRepository repo, {
    required String from,
    required String to,
  }) async {
    final failed = <String>[];
    final List<String> paths;
    try {
      paths = await repo.listNotePaths();
    } catch (_) {
      // Không liệt kê được thư mục: báo cả workspace là chưa sửa được.
      return [repo.workspacePath];
    }
    for (final path in paths) {
      try {
        // Ghi nguyên văn từng byte, chỉ đổi đích link: không serialize lại
        // frontmatter, không bump updatedAt, không trim. Không đổi gì thì
        // không ghi — tránh nhiễu khi sync.
        await repo.rewriteBody(
          path,
          (body) => rewriteNoteLinks(body, from: from, to: to),
        );
      } catch (_) {
        failed.add(path);
      }
    }
    return failed;
  }

  Future<void> delete(String filePath) async {
    final repo = await _ref.read(noteFileRepositoryProvider.future);
    await repo.deleteNote(filePath);
    _ref.invalidate(noteListProvider);
  }
}

final noteActionsProvider = Provider<NoteActions>((ref) => NoteActions(ref));
