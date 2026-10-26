/// Link giữa các note: Markdown chuẩn tương đối `[Tiêu đề](ten-file.md)`,
/// đọc được trên GitHub. Xem DECISIONS.md, "Link giữa các note và tự sửa link
/// khi đổi tên" (2026-10-25).
library;

/// Link Markdown tới note [fileName] với chữ hiển thị [title].
///
/// `\`, `[`, `]` trong tiêu đề được escape bằng `\`; tên file được mã hóa
/// (`%` → `%25`, khoảng trắng → `%20`, ngoặc tròn → `%28`/`%29`) để đích link
/// không bị cắt giữa chừng.
String noteLink(String title, String fileName) {
  final text = title.replaceAllMapped(RegExp(r'[\\\[\]]'), (m) => '\\${m[0]}');
  return '[$text](${_encodeFileName(fileName)})';
}

String _encodeFileName(String fileName) => fileName
    .replaceAll('%', '%25')
    .replaceAll(' ', '%20')
    .replaceAll('(', '%28')
    .replaceAll(')', '%29');

/// Tên file note mà [href] trỏ tới, hoặc `null` nếu [href] không phải link
/// tương đối tới một file `.md`.
///
/// Bỏ các tiền tố `./`, bỏ `#anchor`, giải mã `%XX`. Có scheme (`https:`,
/// `mailto:` …), đường dẫn tuyệt đối (`/…`), hay không phải `.md` → `null`.
String? linkedNoteFileName(String href) {
  var path = href.trim();
  final hash = path.indexOf('#');
  if (hash >= 0) path = path.substring(0, hash);
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*:').hasMatch(path)) return null;
  while (path.startsWith('./')) {
    path = path.substring(2);
  }
  if (path.isEmpty || path.startsWith('/')) return null;
  try {
    path = Uri.decodeComponent(path);
  } on ArgumentError {
    // `%` lẻ không phải mã hóa — giữ nguyên chữ.
  }
  if (!path.toLowerCase().endsWith('.md')) return null;
  return path;
}

/// Đổi đích các link Markdown `[…](…)` trỏ tới note [from] sang [to].
///
/// Chỉ đụng đúng phần tên file trong đích link: giữ tiền tố `./`, `#anchor`,
/// title `"…"` và dạng `<…>`. Không đụng link trong khối code (``` hoặc ~~~,
/// kể cả khối chưa đóng, thụt lề hay trong blockquote; khối thụt 4 khoảng
/// trắng / tab) và trong code giữa dòng, không đụng chữ thường trùng tên
/// file. Link kiểu tham chiếu `[x]: a.md` không được sửa. Không có gì để đổi
/// thì trả về đúng [content].
String rewriteNoteLinks(
  String content, {
  required String from,
  required String to,
}) {
  final lines = content.split('\n');
  var changed = false;
  String? fenceChar;
  var fenceLength = 0;
  // Khối code thụt lề: dòng thụt ≥4 khoảng trắng / tab sau dòng trống (hoặc
  // đầu file) hay nối tiếp một dòng code thụt lề.
  var prevBlank = true;
  var inIndented = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final fence = _fence.firstMatch(line);
    if (fenceChar != null) {
      // Đang trong khối code: chỉ fence cùng loại, dài ít nhất bằng fence mở,
      // không kèm chữ phía sau mới đóng khối.
      if (fence != null &&
          fence[1]![0] == fenceChar &&
          fence[1]!.length >= fenceLength &&
          line.substring(fence.end).trim().isEmpty) {
        fenceChar = null;
        prevBlank = false;
      }
      continue;
    }
    if (fence != null) {
      fenceChar = fence[1]![0];
      fenceLength = fence[1]!.length;
      inIndented = false;
      continue;
    }
    if (line.trim().isEmpty) {
      prevBlank = true;
      continue;
    }
    if (_indented.hasMatch(line) && (prevBlank || inIndented)) {
      inIndented = true;
      prevBlank = false;
      continue;
    }
    inIndented = false;
    prevBlank = false;
    final rewritten = _rewriteLine(line, from, to);
    if (rewritten != line) {
      lines[i] = rewritten;
      changed = true;
    }
  }
  return changed ? lines.join('\n') : content;
}

/// Fence mở/đóng khối code. Cố ý bảo thủ: chấp nhận mọi khoảng trắng và dấu
/// `>` (blockquote) phía trước — coi nhầm là code chỉ để sót một link chưa
/// sửa, còn sửa nhầm trong code thì im lặng làm hỏng dữ liệu.
final _fence = RegExp(r'^[ \t>]*(`{3,}|~{3,})');

final _indented = RegExp(r'^( {4}|\t)');

String _rewriteLine(String line, String from, String to) {
  final out = StringBuffer();
  var depth = 0; // số `[` đang mở
  var i = 0;
  while (i < line.length) {
    final c = line[i];
    if (c == '\\' && i + 1 < line.length) {
      out.write(line.substring(i, i + 2));
      i += 2;
      continue;
    }
    if (c == '`') {
      // Code giữa dòng: dãy N dấu ` đóng bằng đúng N dấu ` sau đó.
      var n = 0;
      while (i + n < line.length && line[i + n] == '`') {
        n++;
      }
      final close = _findBacktickRun(line, i + n, n);
      final end = close < 0 ? i + n : close + n;
      out.write(line.substring(i, end));
      i = end;
      continue;
    }
    if (c == '[') {
      depth++;
    } else if (c == ']' && depth > 0) {
      depth--;
      if (i + 1 < line.length && line[i + 1] == '(') {
        final dest = _parseDestination(line, i + 2);
        if (dest != null) {
          out.write('](');
          out.write(line.substring(i + 2, dest.start));
          final raw = line.substring(dest.start, dest.end);
          out.write(_rewriteTarget(raw, from, to) ?? raw);
          i = dest.end;
          depth = 0;
          continue;
        }
      }
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

int _findBacktickRun(String line, int from, int n) {
  var i = from;
  while (i < line.length) {
    if (line[i] != '`') {
      i++;
      continue;
    }
    var m = 0;
    while (i + m < line.length && line[i + m] == '`') {
      m++;
    }
    if (m == n) return i;
    i += m;
  }
  return -1;
}

/// Vị trí đích link bắt đầu sau `](` tại [start]: dạng `<…>` hoặc chuỗi không
/// có khoảng trắng với ngoặc tròn cân bằng. Phải có `)` đóng (có thể sau
/// title) mới là link. Trả về khoảng của đích (không gồm khoảng trắng đầu).
({int start, int end})? _parseDestination(String line, int start) {
  var i = start;
  while (i < line.length && line[i] == ' ') {
    i++;
  }
  final destStart = i;
  int destEnd;
  if (i < line.length && line[i] == '<') {
    final close = line.indexOf('>', i + 1);
    if (close < 0) return null;
    destEnd = close + 1;
  } else {
    var parens = 0;
    while (i < line.length) {
      final c = line[i];
      if (c == '\\' && i + 1 < line.length) {
        i += 2;
        continue;
      }
      if (c == ' ' || c == '\t') break;
      if (c == '(') parens++;
      if (c == ')') {
        if (parens == 0) break;
        parens--;
      }
      i++;
    }
    destEnd = i;
  }
  if (destEnd == destStart) return null;
  // Sau đích: khoảng trắng, title tùy chọn, rồi `)`.
  var j = destEnd;
  while (j < line.length && line[j] == ' ') {
    j++;
  }
  if (j < line.length && line[j] == ')') {
    return (start: destStart, end: destEnd);
  }
  if (j < line.length && '"\'('.contains(line[j])) {
    final closer = line[j] == '(' ? ')' : line[j];
    final close = line.indexOf(closer, j + 1);
    if (close < 0) return null;
    var k = close + 1;
    while (k < line.length && line[k] == ' ') {
      k++;
    }
    if (k < line.length && line[k] == ')') {
      return (start: destStart, end: destEnd);
    }
  }
  return null;
}

/// Đích mới nếu [raw] trỏ tới [from], ngược lại `null`.
String? _rewriteTarget(String raw, String from, String to) {
  final angled = raw.startsWith('<') && raw.endsWith('>');
  final href = angled ? raw.substring(1, raw.length - 1) : raw;
  if (linkedNoteFileName(href) != from) return null;

  final prefix = RegExp(r'^(\./)*').firstMatch(href)![0]!;
  final hash = href.indexOf('#');
  final suffix = hash >= 0 ? href.substring(hash) : '';
  final target = '$prefix${_encodeFileName(to)}$suffix';
  return angled ? '<$target>' : target;
}
