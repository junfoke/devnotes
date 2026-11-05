import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/domain/text_ops.dart';
import 'package:devnotes/features/editor/presentation/highlight_text_controller.dart';

/// Thanh tìm & thay thế trong note, nằm ngay trên thanh công cụ.
///
/// Tìm theo nghĩa đen, không phân biệt hoa thường. Kết quả được chọn bằng
/// vùng chọn của [text]; mọi lần thay chỉ gán `text.value` để tự lưu và lớp
/// chặn ghi đè thay đổi bên ngoài vẫn bắt được. "Thay hết" là một lần gán
/// duy nhất → hoàn tác một lần là về nội dung cũ.
///
/// Ô tìm giữ focus nên ô soạn không tô vùng chọn: mọi kết quả được tô thẳng
/// trong chữ qua [text] (kết quả đang chọn tô đậm hơn) và [onReveal] cuộn ô
/// soạn tới kết quả đang chọn (ruling R8). Đóng thanh thì hết tô.
class FindReplaceBar extends StatefulWidget {
  const FindReplaceBar({
    super.key,
    required this.text,
    required this.onClose,
    this.onReveal,
  });

  /// Controller của ô soạn. Không đổi trong suốt đời thanh.
  final HighlightTextEditingController text;
  final VoidCallback onClose;

  /// Cuộn ô soạn để thấy đoạn chữ này.
  final ValueChanged<TextRange>? onReveal;

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final _query = TextEditingController();
  final _replacement = TextEditingController();

  /// `autofocus` không đủ: ô soạn thường đang giữ focus lúc mở thanh, mà
  /// autofocus chỉ có tác dụng khi chưa có gì được focus.
  final _queryFocus = FocusNode();

  List<TextRange> _matches = const [];

  /// Kết quả đang chọn, -1 nếu chưa chọn kết quả nào.
  int _current = -1;
  String _lastQuery = '';
  late String _lastText = widget.text.text;

  @override
  void initState() {
    super.initState();
    widget.text.addListener(_onEditorChanged);
    _query.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queryFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(FindReplaceBar old) {
    super.didUpdateWidget(old);
    assert(old.text == widget.text, 'Không hỗ trợ đổi controller ô soạn.');
  }

  @override
  void dispose() {
    widget.text.removeListener(_onEditorChanged);
    // Đang tháo cây widget — không dựng lại ô soạn lúc này; EditorScreen tự
    // dựng lại sau khi ẩn thanh (đóng thanh, sang trang preview).
    widget.text.clearHighlights(notify: false);
    _query.dispose();
    _replacement.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  /// Gõ chữ tìm mới thì chọn kết quả đầu tiên.
  void _onQueryChanged() {
    if (_query.text == _lastQuery) return;
    _lastQuery = _query.text;
    _recompute();
    if (_matches.isNotEmpty) _select(0);
  }

  /// Nội dung note đổi (gõ, công cụ, thay) thì tìm lại. Chỉ dời vùng chọn
  /// (kể cả do chính thanh này chọn kết quả) thì bỏ qua.
  void _onEditorChanged() {
    if (widget.text.text == _lastText) return;
    _lastText = widget.text.text;
    _recompute();
  }

  void _recompute() {
    setState(() {
      _matches = findAll(widget.text.text, _query.text);
      _current = -1;
    });
    _syncHighlights();
  }

  void _select(int index) {
    final m = _matches[index];
    setState(() => _current = index);
    widget.text.selection = TextSelection(
      baseOffset: m.start,
      extentOffset: m.end,
    );
    _syncHighlights();
    widget.onReveal?.call(m);
  }

  /// Tô mọi kết quả trong ô soạn, kết quả đang chọn đậm hơn.
  void _syncHighlights() {
    if (_matches.isEmpty) {
      widget.text.clearHighlights();
      return;
    }
    final colors = Theme.of(context).appColors;
    widget.text.setHighlights(
      _matches,
      current: _current,
      color: colors.warning.withValues(alpha: 0.25),
      currentColor: colors.accent.withValues(alpha: 0.45),
    );
  }

  void _close() {
    widget.text.clearHighlights();
    widget.onClose();
  }

  /// Vị trí con trỏ để tìm kết quả kế tiếp khi chưa chọn kết quả nào.
  int get _cursor {
    final sel = widget.text.selection;
    return sel.isValid ? sel.end : 0;
  }

  /// Kết quả đầu tiên bắt đầu từ [offset] trở đi, hết thì quay về đầu.
  int _firstFrom(int offset) {
    final i = _matches.indexWhere((m) => m.start >= offset);
    return i == -1 ? 0 : i;
  }

  void _next() {
    if (_matches.isEmpty) return;
    _select(
      _current == -1 ? _firstFrom(_cursor) : (_current + 1) % _matches.length,
    );
  }

  void _previous() {
    if (_matches.isEmpty) return;
    if (_current == -1) {
      final i = _matches.lastIndexWhere((m) => m.end <= _cursor);
      _select(i == -1 ? _matches.length - 1 : i);
    } else {
      _select((_current - 1 + _matches.length) % _matches.length);
    }
  }

  /// Thay kết quả đang chọn rồi chọn kết quả kế tiếp. Chưa chọn kết quả nào
  /// thì chỉ chọn kết quả kế tiếp để user thấy trước khi thay.
  void _replaceOne() {
    if (_current == -1) {
      _next();
      return;
    }
    final m = _matches[_current];
    final replacement = _replacement.text;
    final after = m.start + replacement.length;
    widget.text.value = TextEditingValue(
      text: widget.text.text.replaceRange(m.start, m.end, replacement),
      selection: TextSelection.collapsed(offset: after),
    );
    if (_matches.isNotEmpty) _select(_firstFrom(after));
  }

  void _replaceAll() {
    final current = widget.text.text;
    final updated = replaceAllLiteral(current, _query.text, _replacement.text);
    if (updated == current) return;
    // Vùng chọn phải hợp lệ thì lịch sử hoàn tác mới ghi nhận lần đổi này.
    final offset = widget.text.selection.baseOffset
        .clamp(0, updated.length)
        .toInt();
    widget.text.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final hasMatches = _matches.isNotEmpty;
    final fieldStyle = TextStyle(color: colors.textPrimary, fontSize: 14);
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );

    return Material(
      color: colors.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('find-query'),
                    controller: _query,
                    focusNode: _queryFocus,
                    style: fieldStyle,
                    decoration: decoration(l.findQueryHint),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _next(),
                  ),
                ),
                Text(
                  '${_current + 1}/${_matches.length}',
                  key: const Key('find-count'),
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
                IconButton(
                  tooltip: l.findPrevious,
                  onPressed: hasMatches ? _previous : null,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: l.findNext,
                  onPressed: hasMatches ? _next : null,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                IconButton(
                  tooltip: l.findClose,
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('find-replacement'),
                    controller: _replacement,
                    style: fieldStyle,
                    decoration: decoration(l.findReplacementHint),
                  ),
                ),
                TextButton(
                  onPressed: hasMatches ? _replaceOne : null,
                  child: Text(l.findReplaceOne),
                ),
                TextButton(
                  onPressed: hasMatches ? _replaceAll : null,
                  child: Text(l.findReplaceAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
