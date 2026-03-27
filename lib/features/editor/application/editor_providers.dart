import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

final currentNoteProvider = FutureProvider.family<NoteFile, String>(
  (ref, filePath) async {
    final repo = await ref.watch(noteFileRepositoryProvider.future);
    return repo.readNote(filePath);
  },
);

enum SaveStatus { saved, saving, unsaved }

final saveStatusProvider = StateProvider<SaveStatus>((ref) => SaveStatus.saved);
