import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class ExportImportService {
  final String workspacePath;

  ExportImportService({required this.workspacePath});

  Future<String> exportToZip(String outputPath) async {
    final archive = Archive();
    final dir = Directory(workspacePath);
    final files = dir.listSync(recursive: true).whereType<File>();

    for (final file in files) {
      if (!file.path.endsWith('.md')) continue;
      final relativePath = file.path
          .substring(workspacePath.length + 1)
          .replaceAll('\\', '/');
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }

    final zipData = ZipEncoder().encode(archive);
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(zipData);
    return outputPath;
  }

  /// Nhập các file `.md` từ [zipPath] vào workspace.
  ///
  /// Không bao giờ ghi đè hay làm mất note đang có — xem DECISIONS.md, "Import
  /// ZIP: trùng tên thì tạo bản sao":
  /// - Đọc và giải nén **toàn bộ** zip vào bộ nhớ trước; zip hỏng thì ném
  ///   [ImportException] mà chưa ghi file nào.
  /// - Trùng tên + giống hệt từng byte (với note gốc hoặc một bản sao `-N`
  ///   đã có) → bỏ qua, nên nhập lại cùng một zip không sinh thêm file.
  /// - Trùng tên + khác nội dung → ghi bản sao `ten-1.md`, `ten-2.md`…
  /// - Mục có đường dẫn thoát khỏi workspace (`../`, đường dẫn tuyệt đối,
  ///   thư mục `.git` dù viết hoa hay thường) → từ chối (B-16, zip slip).
  /// - Note nằm trong thư mục con được đưa về thư mục gốc của workspace.
  Future<ImportReport> importFromZip(String zipPath) async {
    final List<({String name, List<int> bytes})> entries;
    try {
      final bytes = await File(zipPath).readAsBytes();
      // archive 4.x không ném lỗi với dữ liệu rác mà trả về archive rỗng —
      // phải tự kiểm chữ ký "PK" thì mới phân biệt được zip hỏng với zip rỗng.
      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
        throw const FormatException('missing PK signature');
      }
      final archive = ZipDecoder().decodeBytes(bytes);
      entries = [
        for (final file in archive)
          if (file.isFile && file.name.toLowerCase().endsWith('.md'))
            (name: file.name, bytes: file.content),
      ];
    } catch (e) {
      throw ImportException('$e');
    }

    final report = ImportReport();
    for (final entry in entries) {
      final relative = _safeRelativePath(entry.name);
      if (relative == null) {
        report.rejected.add(entry.name);
        continue;
      }
      final target = p.join(workspacePath, relative);
      if (!p.isWithin(workspacePath, target)) {
        report.rejected.add(entry.name);
        continue;
      }

      final targetFile = File(target);
      if (!targetFile.existsSync()) {
        await targetFile.create(recursive: true);
        await targetFile.writeAsBytes(entry.bytes);
        report.added.add(entry.name);
        continue;
      }
      if (_sameBytes(targetFile, entry.bytes)) {
        report.skippedIdentical.add(entry.name);
        continue;
      }

      // Tìm bản sao -N đầu tiên còn trống; gặp bản sao giống hệt thì dừng.
      final base = p.withoutExtension(target);
      final ext = p.extension(target);
      for (var n = 1; ; n++) {
        final copy = File('$base-$n$ext');
        if (!copy.existsSync()) {
          await copy.writeAsBytes(entry.bytes);
          report.copied[entry.name] = p
              .relative(copy.path, from: workspacePath)
              .replaceAll('\\', '/');
          break;
        }
        if (_sameBytes(copy, entry.bytes)) {
          report.skippedIdentical.add(entry.name);
          break;
        }
      }
    }
    return report;
  }

  /// Chuẩn hóa tên mục trong zip thành đường dẫn tương đối an toàn, hoặc
  /// `null` nếu nó trỏ ra ngoài workspace.
  static String? _safeRelativePath(String name) {
    final unified = name.replaceAll('\\', '/');
    if (unified.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(unified)) {
      return null;
    }
    final normalized = p.posix.normalize(unified);
    final segments = p.posix.split(normalized);
    if (segments.isEmpty ||
        segments.first == '..' ||
        segments.first == '.' ||
        segments.any((s) => s.toLowerCase() == '.git')) {
      return null;
    }
    // App chỉ liệt kê note ở thư mục gốc: note trong thư mục con được đưa về
    // gốc (DECISIONS 2026-10-25), trùng tên thì theo luật bản sao như thường.
    return segments.last;
  }

  static bool _sameBytes(File file, List<int> bytes) {
    final existing = file.readAsBytesSync();
    if (existing.length != bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (existing[i] != bytes[i]) return false;
    }
    return true;
  }
}

/// Kết quả một lần nhập. Tên trong các danh sách là tên mục trong zip.
class ImportReport {
  final List<String> added = [];
  final List<String> skippedIdentical = [];

  /// Tên mục trong zip → đường dẫn bản sao đã ghi (tương đối, dấu `/`).
  final Map<String, String> copied = {};
  final List<String> rejected = [];
}

/// File chọn để nhập không phải ZIP hợp lệ. Câu báo cho user do tầng UI
/// dịch; [detail] là lỗi kỹ thuật gốc, hiện nguyên văn sau câu đó.
class ImportException implements Exception {
  ImportException(this.detail);
  final String detail;

  @override
  String toString() => 'ImportException: not a valid ZIP file: $detail';
}
