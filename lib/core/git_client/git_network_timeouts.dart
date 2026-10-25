import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

/// Đặt thời gian chờ mạng cho libgit2.
///
/// Mặc định libgit2 chờ vô hạn: mạng treo (DNS hỏng, Wi-Fi chập chờn) thì
/// sync quay mãi và giữ khóa, chặn mọi lần sync sau. git2dart không bọc các
/// option này nên gọi thẳng `git_libgit2_opts` (hàm C varargs) qua FFI.
/// Option là toàn cục cho cả tiến trình — gọi một lần ở main là đủ, các
/// isolate chạy git sau đó đều được áp dụng.
///
/// Không nạp được (vd chạy test trên desktop) thì bỏ qua: chỉ mất timeout,
/// không hỏng chức năng.
class GitNetworkTimeouts {
  static const _setServerConnectTimeout = 39; // GIT_OPT_SET_SERVER_CONNECT_TIMEOUT
  static const _setServerTimeout = 41; // GIT_OPT_SET_SERVER_TIMEOUT

  static const connectTimeout = Duration(seconds: 15);
  static const ioTimeout = Duration(seconds: 30);

  static void apply() {
    try {
      final lib = DynamicLibrary.open(
          Platform.isAndroid || Platform.isLinux ? 'libgit2.so' : 'libgit2.dll');
      final opts = lib.lookupFunction<Int Function(Int, VarArgs<(Int,)>),
          int Function(int, int)>('git_libgit2_opts');
      final a = opts(_setServerConnectTimeout, connectTimeout.inMilliseconds);
      final b = opts(_setServerTimeout, ioTimeout.inMilliseconds);
      debugPrint('GitNetworkTimeouts: connect=$a io=$b (0 = ok)');
    } catch (e) {
      debugPrint('GitNetworkTimeouts: không đặt được timeout: $e');
    }
  }
}
