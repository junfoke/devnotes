// Trạng thái đồng bộ phải phản ánh đúng thực tế, không được "xanh sẵn".
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#git-sync
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';

void main() {
  group('SyncStateNotifier', () {
    test('mở app lần đầu: trạng thái là idle, không phải synced', () {
      final notifier = SyncStateNotifier();

      // Chưa sync lần nào trong phiên -> không được khoe "đã đồng bộ".
      expect(notifier.state.status, SyncStatus.idle);
      expect(notifier.state.lastSyncAt, isNull);
    });

    test('sync thành công mới chuyển sang synced và ghi lastSyncAt', () {
      final notifier = SyncStateNotifier();

      notifier.setSyncing();
      expect(notifier.state.status, SyncStatus.syncing);

      notifier.setSynced();
      expect(notifier.state.status, SyncStatus.synced);
      expect(notifier.state.lastSyncAt, isNotNull);
    });

    test('sync lỗi chuyển sang error và không đặt lastSyncAt', () {
      final notifier = SyncStateNotifier();

      notifier.setSyncing();
      notifier.setError();

      expect(notifier.state.status, SyncStatus.error);
      expect(notifier.state.lastSyncAt, isNull);
    });

    test('setBranch đổi tên branch hiển thị', () {
      final notifier = SyncStateNotifier();
      expect(notifier.state.branchName, 'main');

      notifier.setBranch('develop');

      expect(notifier.state.branchName, 'develop');
    });
  });
}
