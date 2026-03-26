// lib/features/workspace/application/workspace_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

final noteListProvider = FutureProvider<List<NoteFile>>((ref) async {
  final repo = await ref.watch(noteFileRepositoryProvider.future);
  return repo.listNotes();
});

final selectedCollectionProvider = StateProvider<String?>((ref) => null);

final createNoteProvider = FutureProvider.family<NoteFile, ({String title, List<String> tags})>(
  (ref, params) async {
    final repo = await ref.read(noteFileRepositoryProvider.future);
    final note = await repo.createNote(title: params.title, tags: params.tags);
    ref.invalidate(noteListProvider);
    return note;
  },
);

final deleteNoteProvider = FutureProvider.family<void, String>(
  (ref, filePath) async {
    final repo = await ref.read(noteFileRepositoryProvider.future);
    await repo.deleteNote(filePath);
    ref.invalidate(noteListProvider);
  },
);

final renameNoteProvider = FutureProvider.family<NoteFile, ({String filePath, String newTitle})>(
  (ref, params) async {
    final repo = await ref.read(noteFileRepositoryProvider.future);
    final note = await repo.renameNote(params.filePath, params.newTitle);
    ref.invalidate(noteListProvider);
    return note;
  },
);
