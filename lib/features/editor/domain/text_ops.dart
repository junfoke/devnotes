import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Các thao tác văn bản thuần cho công cụ soạn thảo. Mọi hàm nhận và trả
/// [TextEditingValue]; vùng chọn đi theo nội dung.

/// Khoảng các dòng chạm vùng chọn: [start] là đầu dòng đầu, [end] là cuối dòng
/// cuối (trước `\n`). Nếu vùng chọn không rỗng và kết thúc đúng đầu một dòng
/// thì dòng đó không tính.
({int start, int end}) _lineBlock(TextEditingValue v) {
  final text = v.text;
  var lo = v.selection.isValid
      ? math.min(v.selection.baseOffset, v.selection.extentOffset)
      : text.length;
  var hi = v.selection.isValid
      ? math.max(v.selection.baseOffset, v.selection.extentOffset)
      : text.length;
  lo = lo.clamp(0, text.length);
  hi = hi.clamp(0, text.length);
  if (hi > lo && hi > 0 && text[hi - 1] == '\n') hi -= 1;
  final start = lo == 0 ? 0 : text.lastIndexOf('\n', lo - 1) + 1;
  final nl = text.indexOf('\n', hi);
  final end = nl == -1 ? text.length : nl;
  return (start: start, end: end);
}

TextSelection _sel(TextEditingValue v) => v.selection.isValid
    ? v.selection
    : TextSelection.collapsed(offset: v.text.length);

TextEditingValue _withSelection(
    String text, TextSelection old, int Function(int) map) {
  int clamp(int o) => map(o).clamp(0, text.length);
  return TextEditingValue(
    text: text,
    selection: TextSelection(
        baseOffset: clamp(old.baseOffset),
        extentOffset: clamp(old.extentOffset),
        affinity: old.affinity),
  );
}

/// Thêm 2 dấu cách đầu mọi dòng chạm vùng chọn.
TextEditingValue indentLines(TextEditingValue v) {
  final b = _lineBlock(v);
  final lines = v.text.substring(b.start, b.end).split('\n');
  final starts = <int>[];
  var pos = b.start;
  for (final l in lines) {
    starts.add(pos);
    pos += l.length + 1;
  }
  final text = v.text.replaceRange(
      b.start, b.end, lines.map((l) => '  $l').join('\n'));
  return _withSelection(text, _sel(v), (o) {
    var n = 0;
    for (final s in starts) {
      if (s <= o) n++;
    }
    return o + 2 * n;
  });
}

/// Bỏ tối đa 2 dấu cách (hoặc 1 tab) đầu mỗi dòng chạm vùng chọn.
TextEditingValue outdentLines(TextEditingValue v) {
  final b = _lineBlock(v);
  final lines = v.text.substring(b.start, b.end).split('\n');
  final starts = <int>[];
  final removed = <int>[];
  var pos = b.start;
  final out = <String>[];
  for (final l in lines) {
    var r = 0;
    if (l.startsWith('\t')) {
      r = 1;
    } else {
      while (r < 2 && r < l.length && l[r] == ' ') {
        r++;
      }
    }
    starts.add(pos);
    removed.add(r);
    out.add(l.substring(r));
    pos += l.length + 1;
  }
  final text = v.text.replaceRange(b.start, b.end, out.join('\n'));
  return _withSelection(text, _sel(v), (o) {
    var shift = 0;
    for (var i = 0; i < starts.length; i++) {
      if (o > starts[i]) {
        shift += math.min(removed[i], o - starts[i]);
      }
    }
    return o - shift;
  });
}

/// Đưa (các) dòng chạm vùng chọn lên/xuống một dòng; ở biên thì giữ nguyên.
TextEditingValue moveLines(TextEditingValue v, {required bool up}) {
  final text = v.text;
  final b = _lineBlock(v);
  final block = text.substring(b.start, b.end);
  if (up) {
    if (b.start == 0) return v;
    final ps = b.start == 1 ? 0 : text.lastIndexOf('\n', b.start - 2) + 1;
    final prev = text.substring(ps, b.start - 1);
    final out =
        '${text.substring(0, ps)}$block\n$prev${text.substring(b.end)}';
    final delta = prev.length + 1;
    return _withSelection(out, _sel(v),
        (o) => o >= b.start && o <= b.end + 1 ? o - delta : o);
  }
  if (b.end >= text.length) return v;
  final nlIdx = text.indexOf('\n', b.end + 1);
  final ne = nlIdx == -1 ? text.length : nlIdx;
  final next = text.substring(b.end + 1, ne);
  final out =
      '${text.substring(0, b.start)}$next\n$block${text.substring(ne)}';
  final delta = next.length + 1;
  return _withSelection(out, _sel(v),
      (o) => o >= b.start && o <= b.end + 1 ? o + delta : o);
}

/// Nhân đôi các dòng chạm vùng chọn (ngay bên dưới); vùng chọn nhảy xuống bản sao.
TextEditingValue duplicateLines(TextEditingValue v) {
  final b = _lineBlock(v);
  final block = v.text.substring(b.start, b.end);
  final out = v.text.replaceRange(b.end, b.end, '\n$block');
  final delta = block.length + 1;
  return _withSelection(
      out, _sel(v), (o) => o >= b.start && o <= b.end + 1 ? o + delta : o);
}

/// Xóa các dòng chạm vùng chọn (kể cả ký tự xuống dòng đi kèm).
TextEditingValue deleteLines(TextEditingValue v) {
  final text = v.text;
  final b = _lineBlock(v);
  int from = b.start;
  int to = b.end;
  if (b.end < text.length) {
    to = b.end + 1;
  } else if (b.start > 0) {
    from = b.start - 1;
  }
  final out = text.replaceRange(from, to, '');
  return TextEditingValue(
      text: out, selection: TextSelection.collapsed(offset: from));
}

/// Thay vùng chọn bằng [text]; [asBlock] thì tự thêm `\n` trước nếu không ở
/// đầu dòng, và `\n` sau nếu phần chữ phía sau còn trên cùng dòng (không để
/// nó dính vào hàng cuối bảng hay dấu ``` đóng khối). Con trỏ nằm ngay sau
/// [text], trước dấu `\n` tự thêm.
TextEditingValue insertAtCursor(TextEditingValue v, String text,
    {bool asBlock = false}) {
  final sel = _sel(v);
  final lo = math.min(sel.baseOffset, sel.extentOffset).clamp(0, v.text.length);
  final hi = math.max(sel.baseOffset, sel.extentOffset).clamp(0, v.text.length);
  final prefix = asBlock && lo > 0 && v.text[lo - 1] != '\n' ? '\n' : '';
  final suffix = asBlock &&
          hi < v.text.length &&
          v.text[hi] != '\n' &&
          !text.endsWith('\n')
      ? '\n'
      : '';
  return TextEditingValue(
    text: v.text.replaceRange(lo, hi, '$prefix$text$suffix'),
    selection:
        TextSelection.collapsed(offset: lo + prefix.length + text.length),
  );
}

/// Bảng Markdown: số cột = số tiêu đề, [rows] hàng trống.
String buildTable(List<String> headers, int rows) {
  final lines = <String>[
    '| ${headers.join(' | ')} |',
    '| ${headers.map((_) => '---').join(' | ')} |',
    for (var i = 0; i < rows; i++) '|${headers.map((_) => '  |').join()}',
  ];
  return lines.join('\n');
}

/// Khối code rỗng với ngôn ngữ [language].
String buildCodeBlock(String language) => '```$language\n\n```';

/// Mọi vị trí khớp [query] theo nghĩa đen (không regex), không chồng lấn.
List<TextRange> findAll(String text, String query,
    {bool caseSensitive = false}) {
  if (query.isEmpty) return const [];
  final re = RegExp(RegExp.escape(query),
      caseSensitive: caseSensitive, unicode: true);
  return [
    for (final m in re.allMatches(text)) TextRange(start: m.start, end: m.end),
  ];
}

/// Thay mọi chỗ khớp [query] bằng [replacement] nguyên văn.
String replaceAllLiteral(String text, String query, String replacement,
    {bool caseSensitive = false}) {
  final matches = findAll(text, query, caseSensitive: caseSensitive);
  if (matches.isEmpty) return text;
  final buf = StringBuffer();
  var last = 0;
  for (final m in matches) {
    buf
      ..write(text.substring(last, m.start))
      ..write(replacement);
    last = m.end;
  }
  buf.write(text.substring(last));
  return buf.toString();
}

/// Các tiêu đề `#`…`######` nằm ngoài khối code; [offset] là đầu dòng.
List<({int level, String title, int offset})> headings(String text) {
  final re = RegExp(r'^(#{1,6})[ \t]+(.*?)[ \t]*$');
  final out = <({int level, String title, int offset})>[];
  var inFence = false;
  var offset = 0;
  for (final line in text.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
    } else if (!inFence) {
      final m = re.firstMatch(line.endsWith('\r')
          ? line.substring(0, line.length - 1)
          : line);
      if (m != null) {
        out.add((level: m.group(1)!.length, title: m.group(2)!, offset: offset));
      }
    }
    offset += line.length + 1;
  }
  return out;
}

/// Số từ, số ký tự và thời gian đọc (200 từ/phút, làm tròn lên, tối thiểu 1
/// khi có chữ, 0 khi rỗng).
({int words, int chars, int readMinutes}) textStats(String text) {
  final words =
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  final minutes = words == 0 ? 0 : math.max(1, (words / 200).ceil());
  return (words: words, chars: text.runes.length, readMinutes: minutes);
}
