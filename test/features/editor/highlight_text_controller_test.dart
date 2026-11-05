// Gõ tiếng Việt bằng bộ gõ (Telex/VNI) thì chữ đang soạn được gạch chân —
// kể cả khi thanh Tìm & thay đang tô các kết quả trong ô soạn.
import 'package:devnotes/features/editor/presentation/highlight_text_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _hit = Color(0xFFFFFF00);
const _current = Color(0xFFFF8800);

/// Các đoạn lá của cây span: (chữ, nền, có gạch chân).
List<(String, Color?, bool)> _leaves(TextSpan root) {
  final out = <(String, Color?, bool)>[];
  void walk(InlineSpan s, TextStyle inherited) {
    if (s is! TextSpan) return;
    final style = inherited.merge(s.style);
    if (s.text != null && s.text!.isNotEmpty) {
      out.add((
        s.text!,
        style.backgroundColor,
        style.decoration?.contains(TextDecoration.underline) ?? false,
      ));
    }
    for (final c in s.children ?? const <InlineSpan>[]) {
      walk(c, style);
    }
  }

  walk(root, const TextStyle());
  return out;
}

void main() {
  late BuildContext ctx;

  Future<void> grabContext(WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );
  }

  HighlightTextEditingController controller(String text, TextRange composing) {
    return HighlightTextEditingController()
      ..value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: composing.end),
        composing: composing,
      )
      ..setHighlights(
        const [TextRange(start: 0, end: 3), TextRange(start: 8, end: 11)],
        current: 0,
        color: _hit,
        currentColor: _current,
      );
  }

  testWidgets('chữ đang soạn được gạch chân và vẫn giữ nền tô tìm kiếm', (
    tester,
  ) async {
    await grabContext(tester);
    // "abc def abc gh": đang soạn "c def a" — chồng lên cả hai kết quả.
    final c = controller(
      'abc def abc gh',
      const TextRange(start: 2, end: 9),
    );
    final leaves = _leaves(
      c.buildTextSpan(context: ctx, style: const TextStyle(), withComposing: true),
    );

    expect(leaves, [
      ('ab', _current, false),
      ('c', _current, true),
      (' def ', null, true),
      ('a', _hit, true),
      ('bc', _hit, false),
      (' gh', null, false),
    ]);
  });

  testWidgets('withComposing = false thì không gạch chân', (tester) async {
    await grabContext(tester);
    final c = controller('abc def abc gh', const TextRange(start: 2, end: 9));
    final leaves = _leaves(
      c.buildTextSpan(
        context: ctx,
        style: const TextStyle(),
        withComposing: false,
      ),
    );

    expect(leaves.any((l) => l.$3), isFalse);
    expect(leaves.map((l) => l.$1).join(), 'abc def abc gh');
    expect(leaves.first, ('abc', _current, false));
  });
}
