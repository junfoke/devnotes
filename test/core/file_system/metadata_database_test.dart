// test/core/file_system/metadata_database_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/utils/enums.dart';

void main() {
  late MetadataDatabase db;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_db_test_');
    db = MetadataDatabase(dbPath: '${tempDir.path}/metadata.db');
  });

  tearDown(() {
    db.close();
    tempDir.deleteSync(recursive: true);
  });

  group('MetadataDatabase', () {
    test('upsertSyncStatus and getSyncStatus', () {
      db.upsertSyncStatus('/notes/test.md', SyncStatus.pending);
      final status = db.getSyncStatus('/notes/test.md');
      expect(status, SyncStatus.pending);
    });

    test('getSyncStatus returns synced for unknown file', () {
      final status = db.getSyncStatus('/notes/unknown.md');
      expect(status, SyncStatus.synced);
    });

    test('setConflictRef and getConflictRef', () {
      db.setConflictRef('/notes/test.md', '/notes/test_CONFLICT.md');
      final ref = db.getConflictRef('/notes/test.md');
      expect(ref, '/notes/test_CONFLICT.md');
    });

    test('clearConflictRef sets null', () {
      db.setConflictRef('/notes/test.md', '/conflict.md');
      db.clearConflictRef('/notes/test.md');
      final ref = db.getConflictRef('/notes/test.md');
      expect(ref, isNull);
    });

    test('deleteFileMetadata removes record', () {
      db.upsertSyncStatus('/notes/test.md', SyncStatus.pending);
      db.deleteFileMetadata('/notes/test.md');
      final status = db.getSyncStatus('/notes/test.md');
      expect(status, SyncStatus.synced); // defaults back to synced
    });

    test('addSyncLogEntry and getSyncLog', () {
      db.addSyncLogEntry(action: SyncAction.push, filesChanged: 3, success: true);
      db.addSyncLogEntry(action: SyncAction.pull, filesChanged: 1, success: false, errorMessage: 'Network error');
      final log = db.getSyncLog(limit: 10);
      expect(log.length, 2);
      expect(log[0].action, SyncAction.pull); // most recent first
      expect(log[0].success, false);
      expect(log[0].errorMessage, 'Network error');
      expect(log[1].action, SyncAction.push);
      expect(log[1].success, true);
    });
  });
}
