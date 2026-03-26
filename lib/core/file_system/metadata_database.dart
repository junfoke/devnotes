// lib/core/file_system/metadata_database.dart
import 'package:sqlite3/sqlite3.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';

class MetadataDatabase {
  final Database _db;

  MetadataDatabase({required String dbPath}) : _db = sqlite3.open(dbPath) {
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS file_metadata (
        file_path TEXT PRIMARY KEY,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        conflict_ref TEXT
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        action TEXT NOT NULL,
        files_changed INTEGER NOT NULL,
        success INTEGER NOT NULL,
        error_message TEXT
      )
    ''');
  }

  void upsertSyncStatus(String filePath, SyncStatus status) {
    _db.execute(
      'INSERT INTO file_metadata (file_path, sync_status) VALUES (?, ?) ON CONFLICT(file_path) DO UPDATE SET sync_status = ?',
      [filePath, status.name, status.name],
    );
  }

  SyncStatus getSyncStatus(String filePath) {
    final result = _db.select('SELECT sync_status FROM file_metadata WHERE file_path = ?', [filePath]);
    if (result.isEmpty) return SyncStatus.synced;
    return SyncStatus.values.firstWhere(
      (e) => e.name == result.first['sync_status'],
      orElse: () => SyncStatus.synced,
    );
  }

  void setConflictRef(String filePath, String conflictRef) {
    _db.execute(
      "INSERT INTO file_metadata (file_path, sync_status, conflict_ref) VALUES (?, 'conflict', ?) ON CONFLICT(file_path) DO UPDATE SET conflict_ref = ?, sync_status = 'conflict'",
      [filePath, conflictRef, conflictRef],
    );
  }

  String? getConflictRef(String filePath) {
    final result = _db.select('SELECT conflict_ref FROM file_metadata WHERE file_path = ?', [filePath]);
    if (result.isEmpty) return null;
    return result.first['conflict_ref'] as String?;
  }

  void clearConflictRef(String filePath) {
    _db.execute(
      'UPDATE file_metadata SET conflict_ref = NULL, sync_status = ? WHERE file_path = ?',
      [SyncStatus.synced.name, filePath],
    );
  }

  void deleteFileMetadata(String filePath) {
    _db.execute('DELETE FROM file_metadata WHERE file_path = ?', [filePath]);
  }

  void addSyncLogEntry({
    required SyncAction action,
    required int filesChanged,
    required bool success,
    String? errorMessage,
  }) {
    _db.execute(
      'INSERT INTO sync_log (timestamp, action, files_changed, success, error_message) VALUES (?, ?, ?, ?, ?)',
      [DateTime.now().toUtc().toIso8601String(), action.name, filesChanged, success ? 1 : 0, errorMessage],
    );
  }

  List<SyncLogEntry> getSyncLog({int limit = 50}) {
    final result = _db.select('SELECT * FROM sync_log ORDER BY id DESC LIMIT ?', [limit]);
    return result.map((row) {
      return SyncLogEntry(
        timestamp: DateTime.parse(row['timestamp'] as String),
        action: SyncAction.values.firstWhere((e) => e.name == row['action']),
        filesChanged: row['files_changed'] as int,
        success: (row['success'] as int) == 1,
        errorMessage: row['error_message'] as String?,
      );
    }).toList();
  }

  void close() {
    _db.dispose();
  }
}
