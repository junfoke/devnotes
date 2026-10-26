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
    final children = <TextSpan>[];
    var last = 0;
    for (var i = 0; i < _ranges.length; i++) {
      final r = _ranges[i];
      // Chữ vừa đổi mà danh sách tô chưa kịp cập nhật: bỏ đoạn không hợp lệ.
      if (r.start < last || r.end > text.length || r.start >= r.end) continue;
      if (r.start > last) {
        children.add(TextSpan(text: text.substring(last, r.start)));
      }
      children.add(
        TextSpan(
          text: text.substring(r.start, r.end),
          style: TextStyle(
            backgroundColor: i == _current ? _currentColor : _color,
          ),
        ),
      );
      last = r.end;
    }
    if (last < text.length) children.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: children);
  }
}
