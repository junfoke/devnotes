import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

/// Note đang mở trong editor. autoDispose: đóng editor là bỏ cache, lần mở
/// sau đọc lại từ đĩa — không thì sync kéo bản mới về mà mở note vẫn thấy
/// nội dung cũ trong bộ nhớ.
final currentNoteProvider = FutureProvider.autoDispose.family<NoteFile, String>(
  (ref, filePath) async {
    final repo = await ref.watch(noteFileRepositoryProvider.future);
    return repo.readNote(filePath);
  },
);

enum SaveStatus { saved, saving, unsaved }

final saveStatusProvider = StateProvider<SaveStatus>((ref) => SaveStatus.saved);

/// Số editor đang mở. Sync tự động hoãn lại khi > 0 — pull lúc đang soạn sẽ
/// làm nội dung trên màn hình lệch với file trên đĩa. Xem DECISIONS.md,
/// "Editor không ghi đè thay đổi từ bên ngoài" (2026-10-25).
final openEditorCountProvider = StateProvider<int>((ref) => 0);
