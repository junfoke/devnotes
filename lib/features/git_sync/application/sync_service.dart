// lib/features/git_sync/application/sync_service.dart
import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';
import 'package:devnotes/core/file_system/note_file_repository.dart';
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
  final SearchEngine searchEngine;
  final NoteFileRepository noteRepo;

  SyncService({
    required this.gitClient,
    required this.metadataDb,
    required this.searchEngine,
    required this.noteRepo,
  });

  Future<SyncResult> sync(GitConfig config) async {
    try {
      // 1. Pull
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

      // 2. Check for local changes
      final hasChanges = await gitClient.hasChanges();
      if (hasChanges) {
        final timestamp = DateTime.now().toUtc().toIso8601String();
        await gitClient.commitAll('DevNotes sync $timestamp');
        await gitClient.push(
          username: config.username,
          password: config.pat,
        );
      }

      // 3. Update metadata
      final totalChanged = pullResult.filesChanged + (hasChanges ? 1 : 0);
      metadataDb.addSyncLogEntry(
        action: hasChanges ? SyncAction.push : SyncAction.pull,
        filesChanged: totalChanged,
        success: true,
      );

      // 4. Rebuild search index for changed files
      final notes = await noteRepo.listNotes();
      searchEngine.rebuildIndex(notes.map((n) => <String, String>{
        'filePath': n.filePath,
        'title': n.title,
        'tags': n.tags.join(', '),
        'content': n.content,
      }).toList());

      return SyncResult(success: true, filesChanged: totalChanged);
    } catch (e) {
      metadataDb.addSyncLogEntry(
        action: SyncAction.push,
        filesChanged: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return SyncResult(success: false, error: e.toString());
    }
  }
}
