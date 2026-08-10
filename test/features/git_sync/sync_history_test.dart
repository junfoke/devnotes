// Lịch sử đồng bộ phải đọc từ SQLite (bền qua khởi động lại app), không phải
// từ danh sách trong bộ nhớ vốn luôn rỗng.
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#git-sync
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/application/metadata_database_provider.dart';

void main() {
  late Directory tempDir;
  late MetadataDatabase db;
  late ProviderContainer container;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_synclog_');
    db = MetadataDatabase(dbPath: p.join(tempDir.path, 'metadata.db'));
    container = ProviderContainer(
      overrides: [
        metadataDatabaseProvider.overrideWith((ref) async => db),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
    tempDir.deleteSync(recursive: true);
  });

  group('syncHistoryProvider', () {
    test('chưa sync lần nào thì lịch sử rỗng', () async {
      expect(await container.read(syncHistoryProvider.future), isEmpty);
    });

    test('mọi lần sync đều xuất hiện, kể cả lần thất bại', () async {
      db.addSyncLogEntry(
        action: SyncAction.pull,
        filesChanged: 0,
        success: false,
        errorMessage: 'Incorrect credentials.',
      );
      db.addSyncLogEntry(
        action: SyncAction.push,
        filesChanged: 3,
        success: true,
      );

      final entries = await container.read(syncHistoryProvider.future);

      expect(entries.length, 2);
      // Mới nhất lên đầu.
      expect(entries.first.action, SyncAction.push);
      expect(entries.first.filesChanged, 3);
      expect(entries.last.success, isFalse);
      expect(entries.last.errorMessage, 'Incorrect credentials.');
    });

    test('chỉ trả tối đa 20 bản ghi gần nhất', () async {
      for (var i = 0; i < 25; i++) {
        db.addSyncLogEntry(
          action: SyncAction.push,
          filesChanged: i,
          success: true,
        );
      }

      final entries = await container.read(syncHistoryProvider.future);

      expect(entries.length, 20);
      expect(entries.first.filesChanged, 24); // bản ghi mới nhất
    });
  });

  group('lastSuccessfulSyncProvider', () {
    test('chưa có lần sync thành công nào thì trả null', () async {
      db.addSyncLogEntry(
        action: SyncAction.pull,
        filesChanged: 0,
        success: false,
        errorMessage: 'boom',
      );

      expect(await container.read(lastSuccessfulSyncProvider.future), isNull);
    });

    test('bỏ qua các lần thất bại sau đó, lấy lần thành công gần nhất',
        () async {
      db.addSyncLogEntry(
          action: SyncAction.push, filesChanged: 1, success: true);
      db.addSyncLogEntry(
          action: SyncAction.pull,
          filesChanged: 0,
          success: false,
          errorMessage: 'boom');

      final lastSuccess =
          await container.read(lastSuccessfulSyncProvider.future);
      final entries = await container.read(syncHistoryProvider.future);
      final successEntry = entries.firstWhere((e) => e.success);

      expect(lastSuccess, isNotNull);
      expect(lastSuccess, successEntry.timestamp);
    });
  });
}
