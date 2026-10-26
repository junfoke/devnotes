/// Đổi trạng thái ô checklist thứ [index] (đếm từ 0, theo thứ tự xuất hiện
/// trong preview) thành [checked], trả về văn bản Markdown mới.
///
/// Đếm giống cách preview hiển thị: chỉ các dòng `- [ ]` / `* [x]` / `+ [X]`
/// nằm ngoài khối code ``` mới là ô checklist. Không tìm thấy ô thì trả về
/// nguyên văn bản cũ.
String toggleChecklistItem(String source, int index, bool checked) {
  final lines = source.split('\n');
  final item = RegExp(r'^(\s*[-*+]\s+\[)([ xX])(\])');
  var inFence = false;
  var seen = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final match = item.firstMatch(line);
    if (match == null) continue;
    if (seen == index) {
      lines[i] = line.replaceRange(
          match.start + match.group(1)!.length,
          match.start + match.group(1)!.length + 1,
          checked ? 'x' : ' ');
      return lines.join('\n');
    }
    seen++;
  }
  return source;
}

/// Số ô checklist mà preview sẽ hiển thị (cùng luật đếm với
/// [toggleChecklistItem]).
int countChecklistItems(String source) {
  final item = RegExp(r'^\s*[-*+]\s+\[[ xX]\]');
  var inFence = false;
  var count = 0;
  for (final line in source.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence && item.hasMatch(line)) count++;
  }
  return count;
}
