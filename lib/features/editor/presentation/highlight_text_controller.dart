import 'package:flutter/material.dart';

/// Controller của ô soạn, tô nền được một số đoạn chữ (kết quả tìm kiếm).
///
/// Việc tô chỉ ảnh hưởng cách vẽ: [text]/[value] không đổi, nên tự lưu, lớp
/// chặn ghi đè thay đổi bên ngoài và lịch sử hoàn tác không bị ảnh hưởng.
/// Cần vì ô tìm giữ focus — `TextField` không focus thì không tô vùng chọn,
/// user sẽ không thấy chữ nào sắp bị thay (ruling R8).
class HighlightTextEditingController extends TextEditingController {
  List<TextRange> _ranges = const [];
  int _current = -1;
  Color? _color;
  Color? _currentColor;

  List<TextRange> get highlights => _ranges;

  /// Tô [ranges]; đoạn thứ [current] dùng [currentColor], các đoạn khác
  /// dùng [color].
  void setHighlights(
    List<TextRange> ranges, {
    required int current,
    required Color color,
    required Color currentColor,
  }) {
    _ranges = ranges;
    _current = current;
    _color = color;
    _currentColor = currentColor;
    notifyListeners();
  }

  /// Bỏ tô. [notify] = false khi đang tháo cây widget (không được dựng lại
  /// lúc đó); cây bên trên tự dựng lại sau.
  void clearHighlights({bool notify = true}) {
    if (_ranges.isEmpty) return;
    _ranges = const [];
    _current = -1;
    if (notify) notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (_ranges.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    // Đoạn đang soạn của bộ gõ (Telex/VNI) phải được gạch chân như
    // TextEditingController gốc, kể cả khi đè lên đoạn đang tô.
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : null;
    final valid = <int>[];
    var end = 0;
    for (var i = 0; i < _ranges.length; i++) {
      final r = _ranges[i];
      // Chữ vừa đổi mà danh sách tô chưa kịp cập nhật: bỏ đoạn không hợp lệ.
      if (r.start < end || r.end > text.length || r.start >= r.end) continue;
      valid.add(i);
      end = r.end;
    }
    final cuts = <int>{
      0,
      text.length,
      for (final i in valid) ...[_ranges[i].start, _ranges[i].end],
      if (composing != null) ...[composing.start, composing.end],
    }.toList()..sort();

    final children = <TextSpan>[];
    var k = 0; // Chỉ số trong [valid] của đoạn tô có thể chứa vị trí hiện tại.
    for (var j = 0; j + 1 < cuts.length; j++) {
      final a = cuts[j];
      final b = cuts[j + 1];
      if (a >= b) continue;
      while (k < valid.length && _ranges[valid[k]].end <= a) {
        k++;
      }
      final hit = k < valid.length && _ranges[valid[k]].start <= a
          ? valid[k]
          : null;
      final underline =
          composing != null && composing.start <= a && b <= composing.end;
      children.add(
        TextSpan(
          text: text.substring(a, b),
          style: hit == null && !underline
              ? null
              : TextStyle(
                  backgroundColor: hit == null
                      ? null
                      : (hit == _current ? _currentColor : _color),
                  decoration: underline ? TextDecoration.underline : null,
                ),
        ),
      );
    }
    return TextSpan(style: style, children: children);
  }
}
