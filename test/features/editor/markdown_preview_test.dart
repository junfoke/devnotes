// Trang xem trước: tô màu code theo ngôn ngữ, theo cỡ chữ đã chọn, và không
// được crash với khối code ghi ngôn ngữ lạ.
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/presentation/widgets/markdown_preview.dart';
import 'package:devnotes/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, String data, {double size = 14}) =>
    tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      theme: AppTheme.light(),
      home: Scaffold(
        body: MarkdownPreview(
            data: data, fontFamily: 'JetBrainsMono', fontSize: size),
      ),
    ));

void main() {
  testWidgets('khối code có ngôn ngữ được tô màu cú pháp', (tester) async {
    await _pump(tester, '```dart\nvoid main() {}\n```\n');

    final view = tester.widget<HighlightView>(find.byType(HighlightView));
    expect(view.language, 'dart');
  });

  testWidgets('ngôn ngữ lạ không làm crash, hiện dạng chữ thường',
      (tester) async {
    await _pump(tester, '```khongcongonngunay\nabc\n```\n');

    expect(tester.takeException(), isNull);
    final view = tester.widget<HighlightView>(find.byType(HighlightView));
    expect(view.language, 'plaintext');
  });

  testWidgets('code trong dòng giữ kiểu mặc định, không thành khối',
      (tester) async {
    await _pump(tester, 'Gọi `print()` nhé');

    expect(find.byType(HighlightView), findsNothing);
  });

  testWidgets('cỡ chữ đoạn văn và tiêu đề theo cài đặt', (tester) async {
    await _pump(tester, '# Tiêu đề\n\nXin chào', size: 20);

    final sheet = tester.widget<Markdown>(find.byType(Markdown)).styleSheet!;
    expect(sheet.p!.fontSize, 20);
    expect(sheet.h1!.fontSize, greaterThan(20));
  });
}
