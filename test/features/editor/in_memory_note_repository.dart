import 'dart:io';

import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';

/// Repository giữ note trong bộ nhớ cho widget test.
///
/// `testWidgets` chạy trên đồng hồ giả: I/O file thật bên trong nó không bao
/// giờ hoàn tất, test treo vô hạn. Repository này không đụng đĩa.
class InMemoryNoteRepository extends NoteFileRepository {
  InMemoryNoteRepository() : super(workspacePath: '/memory');

  final Map<String, NoteFile> notes = {};

  /// Đặt `true` để mọi lần ghi đều lỗi (giả lập đĩa đầy, mất quyền...).
  bool failOnSave = false;

  NoteFile seed({required String fileName, required String content}) {
    final now = DateTime.utc(2026, 1, 1);
    final note = NoteFile(
      filePath: '$workspacePath/$fileName',
      title: 'Ghi chú',
      tags: const [],
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.idle,
      content: content,
    );
    notes[note.filePath] = note;
    return note;
  }

  /// Đặt `true` để mọi lần đọc đều lỗi (giả lập file hỏng, mất quyền...).
  bool failOnRead = false;

  @override
  Future<NoteFile> readNote(String filePath) async {
    if (failOnRead) {
      throw const FileSystemException('Permission denied');
    }
    return notes[filePath]!;
  }

  @override
  Future<void> saveNote(NoteFile note) async {
    if (failOnSave) {
      throw const FileSystemException('No space left on device');
    }
    notes[note.filePath] = note;
  }

  @override
  Future<void> deleteNote(String filePath) async {
    notes.remove(filePath);
  }

  @override
  Future<NoteFile> renameNote(String oldPath, String newTitle) async {
    final old = notes.remove(oldPath)!;
    final renamed = old.copyWith(
      filePath: '$workspacePath/${newTitle.toLowerCase()}.md',
      title: newTitle,
    );
    notes[renamed.filePath] = renamed;
    return renamed;
  }

  @override
  Future<NoteFile> createNote({
    required String title,
    required List<String> tags,
  }) async {
    final note = seed(
      fileName: 'note-${notes.length + 1}.md',
      content: '',
    ).copyWith(title: title, tags: tags);
    notes[note.filePath] = note;
    return note;
  }
}
