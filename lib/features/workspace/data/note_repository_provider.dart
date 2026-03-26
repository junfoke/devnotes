// lib/features/workspace/data/note_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';

final noteFileRepositoryProvider = FutureProvider<NoteFileRepository>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return NoteFileRepository(workspacePath: path);
});
