// lib/core/git_client/remote_check.dart
//
// Kiểm tra kết nối tới Git remote trước khi lưu credential.
//
// Phần gọi mạng nằm ở `Git2dartClient.checkRemote` (cần libgit2, chỉ chạy được
// trên thiết bị). Toàn bộ logic quyết định "lỗi này nghĩa là gì" nằm ở đây
// dưới dạng hàm thuần để có test chạy được ở mọi môi trường.

/// Kết luận của một lần kiểm tra kết nối remote.
enum RemoteCheckStatus {
  /// Kết nối được và branch cần dùng đã sẵn sàng (hoặc remote còn rỗng).
  ok,

  /// Remote từ chối username/PAT.
  invalidCredentials,

  /// Remote trả về "không tìm thấy" cho URL này.
  repoNotFound,

  /// Không ra được tới remote (DNS, mất mạng, timeout).
  networkUnreachable,

  /// Kết nối được nhưng remote không có branch đã cấu hình.
  branchNotFound,

  /// Không nhận ra lỗi — giữ nguyên thông điệp gốc thay vì đoán bừa.
  unknown,
}

class RemoteCheckResult {
  const RemoteCheckResult(this.status, {this.detail, this.remoteBranches = const []});

  final RemoteCheckStatus status;

  /// Thông điệp gốc từ libgit2, dùng khi [status] là [RemoteCheckStatus.unknown].
  final String? detail;

  /// Các branch tìm thấy trên remote (chỉ có khi kết nối thành công).
  final List<String> remoteBranches;

  bool get ok => status == RemoteCheckStatus.ok;

  // Câu chữ hiển thị cho user nằm ở tầng UI (đa ngôn ngữ): xem
  // `describeRemoteCheck` trong features/git_sync/presentation/git_messages.dart.
}

/// Suy ra loại lỗi từ thông điệp libgit2/git2dart trả về.
///
/// Cố ý so khớp chuỗi vì libgit2 gộp gần hết lỗi mạng/HTTP vào một mã lỗi
/// chung; thông điệp là thứ duy nhất phân biệt được. Không nhận ra thì trả
/// [RemoteCheckStatus.unknown] để còn hiện nguyên văn cho người dùng.
RemoteCheckStatus classifyRemoteError(String message) {
  final text = message.toLowerCase();

  bool has(String needle) => text.contains(needle);

  if (has('incorrect credentials') ||
      has('authentication') ||
      has('unauthorized') ||
      has('401')) {
    return RemoteCheckStatus.invalidCredentials;
  }
  if (has('404') || has('not found')) {
    return RemoteCheckStatus.repoNotFound;
  }
  if (has('failed to resolve') ||
      has('failed to connect') ||
      has('could not resolve') ||
      has('timed out') ||
      has('timeout') ||
      has('unreachable') ||
      has('connection refused')) {
    return RemoteCheckStatus.networkUnreachable;
  }
  return RemoteCheckStatus.unknown;
}

/// Đánh giá danh sách ref lấy được từ remote.
///
/// Remote rỗng (chưa có ref nào) được coi là **hợp lệ**: đó là repo mới tạo,
/// lần sync đầu tiên sẽ init và đẩy lên. Chỉ báo thiếu branch khi remote đã có
/// dữ liệu mà không có branch đang cấu hình — lúc đó sync sẽ hỏng.
RemoteCheckResult evaluateRemoteRefs({
  required List<String> refNames,
  required String branch,
}) {
  final branches = refNames
      .where((name) => name.startsWith('refs/heads/'))
      .map((name) => name.substring('refs/heads/'.length))
      .toList();

  if (branches.isEmpty) {
    return const RemoteCheckResult(RemoteCheckStatus.ok);
  }
  if (!branches.contains(branch)) {
    return RemoteCheckResult(
      RemoteCheckStatus.branchNotFound,
      remoteBranches: branches,
    );
  }
  return RemoteCheckResult(
    RemoteCheckStatus.ok,
    remoteBranches: branches,
  );
}
