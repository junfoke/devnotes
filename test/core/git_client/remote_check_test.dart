// Phân loại kết quả kiểm tra kết nối remote.
//
// Phần gọi mạng thật chỉ chạy được trên thiết bị (libgit2), nên logic phân
// loại được tách thành hàm thuần để có test chạy được ở mọi nơi.
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#git-sync
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/git_client/remote_check.dart';

void main() {
  group('classifyRemoteError', () {
    test('git2dart báo "Incorrect credentials" -> sai thông tin đăng nhập', () {
      expect(
        classifyRemoteError(
            'error: git_error_t.GIT_ERROR_INVALID: Incorrect credentials.'),
        RemoteCheckStatus.invalidCredentials,
      );
    });

    test('HTTP 401 -> sai thông tin đăng nhập', () {
      expect(
        classifyRemoteError('request failed with status code: 401'),
        RemoteCheckStatus.invalidCredentials,
      );
    });

    test('HTTP 404 -> không tìm thấy repository', () {
      expect(
        classifyRemoteError('request failed with status code: 404'),
        RemoteCheckStatus.repoNotFound,
      );
    });

    test('không phân giải được tên miền -> lỗi mạng', () {
      expect(
        classifyRemoteError('failed to resolve address for github.com'),
        RemoteCheckStatus.networkUnreachable,
      );
    });

    test('hết thời gian chờ -> lỗi mạng', () {
      expect(
        classifyRemoteError('failed to connect to github.com: timed out'),
        RemoteCheckStatus.networkUnreachable,
      );
    });

    test('lỗi lạ -> unknown, không đoán bừa', () {
      expect(
        classifyRemoteError('something nobody has seen before'),
        RemoteCheckStatus.unknown,
      );
    });
  });

  group('evaluateRemoteRefs', () {
    test('remote có branch cần dùng -> ok', () {
      final result = evaluateRemoteRefs(
        refNames: ['refs/heads/main', 'refs/heads/dev', 'HEAD'],
        branch: 'main',
      );

      expect(result.status, RemoteCheckStatus.ok);
      expect(result.ok, isTrue);
    });

    test('remote hoàn toàn rỗng -> ok (repo mới, sync sẽ đẩy lên)', () {
      final result = evaluateRemoteRefs(refNames: const [], branch: 'main');

      expect(result.status, RemoteCheckStatus.ok);
    });

    test('remote có dữ liệu nhưng thiếu branch -> báo thiếu branch', () {
      final result = evaluateRemoteRefs(
        refNames: ['refs/heads/master'],
        branch: 'main',
      );

      expect(result.status, RemoteCheckStatus.branchNotFound);
      expect(result.describe(branch: 'main'), contains('main'));
      expect(result.describe(branch: 'main'), contains('master'));
    });
  });

  group('describe', () {
    test('mỗi loại lỗi có thông báo tiếng Việt riêng, không rỗng', () {
      for (final status in RemoteCheckStatus.values) {
        final message =
            RemoteCheckResult(status).describe(branch: 'main');
        expect(message.trim(), isNotEmpty, reason: 'thiếu thông báo cho $status');
      }
    });

    test('lỗi unknown giữ nguyên thông điệp gốc để còn debug', () {
      final result = RemoteCheckResult(
        RemoteCheckStatus.unknown,
        detail: 'raw libgit2 boom',
      );

      expect(result.describe(branch: 'main'), contains('raw libgit2 boom'));
    });
  });
}
