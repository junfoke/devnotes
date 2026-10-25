// lib/features/workspace/application/workspace_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<NoteFile> rename(String filePath, String newTitle) async {
    final repo = await _ref.read(noteFileRepositoryProvider.future);
    final note = await repo.renameNote(filePath, newTitle);
    _ref.invalidate(noteListProvider);
    return note;
  }

  Future<void> delete(String filePath) async {
    final repo = await _ref.read(noteFileRepositoryProvider.future);
    await repo.deleteNote(filePath);
    _ref.invalidate(noteListProvider);
  }
}

final noteActionsProvider = Provider<NoteActions>((ref) => NoteActions(ref));
