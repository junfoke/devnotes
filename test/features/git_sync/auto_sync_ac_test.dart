// Sync tự động (Settings → Sync Frequency).
//
// Quyết định: DECISIONS.md — "Sync tự động" (2026-10-24)
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/application/auto_sync_policy.dart';
import 'package:devnotes/features/git_sync/application/sync_runner.dart';
import 'package:devnotes/features/git_sync/application/sync_service.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);

  group('AutoSyncPolicy', () {
    bool should(SyncFrequency f, AutoSyncTrigger t, {DateTime? last}) =>
        AutoSyncPolicy.shouldRun(
            frequency: f, trigger: t, lastAutoSyncAt: last, now: now);

    test('chế độ thủ công thì không bao giờ tự sync', () {
      for (final t in AutoSyncTrigger.values) {
        expect(should(SyncFrequency.manual, t), isFalse, reason: '$t');
      }
    });

    test('chế độ khi mở app: mở app thì sync, timer thì không', () {
      expect(should(SyncFrequency.onOpen, AutoSyncTrigger.appOpen), isTrue);
      expect(should(SyncFrequency.onOpen, AutoSyncTrigger.timer), isFalse);
    });

    test('quay lại app trong vòng 5 phút sau lần tự sync trước thì bỏ qua', () {
      final recent = now.subtract(const Duration(minutes: 4));
      final old = now.subtract(const Duration(minutes: 6));

      expect(
          should(SyncFrequency.onOpen, AutoSyncTrigger.appResume, last: recent),
          isFalse);
      expect(should(SyncFrequency.onOpen, AutoSyncTrigger.appResume, last: old),
          isTrue);
      expect(should(SyncFrequency.onOpen, AutoSyncTrigger.appResume), isTrue);
    });

    test('chế độ định kỳ: timer, mở app và quay lại app đều sync', () {
      expect(should(SyncFrequency.periodic, AutoSyncTrigger.timer), isTrue);
      expect(should(SyncFrequency.periodic, AutoSyncTrigger.appOpen), isTrue);
      expect(should(SyncFrequency.periodic, AutoSyncTrigger.appResume),
          isTrue);
    });
  });

  group('SyncRunner', () {
    const config = GitConfig(
        remoteUrl: 'https://example.com/n.git', username: 'u', pat: 'p');

    test('đang có một lần sync chạy thì lần thứ hai bị bỏ qua', () async {
      final gate = Completer<void>();
      var syncCalls = 0;
      final runner = SyncRunner(
        loadConfig: () async => config,
        hasUnresolvedConflicts: () async => false,
        prepareRepo: (_) async {},
        doSync: (_) async {
          syncCalls++;
          await gate.future;
          return const SyncResult(success: true);
        },
      );

      final first = runner.run();
      final second = await runner.run();
      gate.complete();
      final firstOutcome = await first;

      expect(second.skipped, SyncSkipReason.alreadyRunning);
      expect(firstOutcome.result?.success, isTrue);
      expect(syncCalls, 1);
    });

    test('chưa cấu hình git thì bỏ qua, không gọi sync', () async {
      var syncCalls = 0;
      final runner = SyncRunner(
        loadConfig: () async => null,
        hasUnresolvedConflicts: () async => false,
        prepareRepo: (_) async {},
        doSync: (_) async {
          syncCalls++;
          return const SyncResult(success: true);
        },
      );

      final outcome = await runner.run(auto: true);

      expect(outcome.skipped, SyncSkipReason.notConfigured);
      expect(syncCalls, 0);
    });

    test('sync tự động bỏ qua khi repo còn conflict chưa giải quyết', () async {
      var syncCalls = 0;
      final runner = SyncRunner(
        loadConfig: () async => config,
        hasUnresolvedConflicts: () async => true,
        prepareRepo: (_) async {},
        doSync: (_) async {
          syncCalls++;
          return const SyncResult(success: true);
        },
      );

      final outcome = await runner.run(auto: true);

      expect(outcome.skipped, SyncSkipReason.unresolvedConflicts);
      expect(syncCalls, 0);
    });

    test('lỗi khi sync không làm kẹt khóa — lần sau vẫn chạy được', () async {
      var attempt = 0;
      final runner = SyncRunner(
        loadConfig: () async => config,
        hasUnresolvedConflicts: () async => false,
        prepareRepo: (_) async {},
        doSync: (_) async {
          attempt++;
          if (attempt == 1) throw Exception('mất mạng');
          return const SyncResult(success: true);
        },
      );

      final first = await runner.run();
      final second = await runner.run();

      expect(first.error, isNotNull);
      expect(second.result?.success, isTrue);
    });

    // Chuyển branch / đánh dấu đã giải quyết cũng đụng vào repo — phải dùng
    // chung khóa với sync, nếu không hai isolate cùng ghi index một lúc.
    test('thao tác git khác đang chạy thì sync bị bỏ qua', () async {
      final gate = Completer<void>();
      var syncCalls = 0;
      final runner = SyncRunner(
        loadConfig: () async => config,
        hasUnresolvedConflicts: () async => false,
        prepareRepo: (_) async {},
        doSync: (_) async {
          syncCalls++;
          return const SyncResult(success: true);
        },
      );

      final switching = runner.exclusive(() => gate.future);
      final outcome = await runner.run(auto: true);
      gate.complete();
      await switching;

      expect(outcome.skipped, SyncSkipReason.alreadyRunning);
      expect(syncCalls, 0);
    });

    test('đang sync thì thao tác git khác báo bận, không chạy chồng', () async {
      final gate = Completer<void>();
      final runner = SyncRunner(
        loadConfig: () async => config,
        hasUnresolvedConflicts: () async => false,
        prepareRepo: (_) async {},
        doSync: (_) async {
          await gate.future;
          return const SyncResult(success: true);
        },
      );

      final syncing = runner.run();
      await expectLater(
          runner.exclusive(() async => 1), throwsA(isA<GitBusyException>()));
      gate.complete();
      await syncing;

      expect(await runner.exclusive(() async => 1), 1);
    });
  });
}
