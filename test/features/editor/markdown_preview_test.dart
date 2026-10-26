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

  testWidgets('bấm ô checklist báo đúng ô thứ mấy và trạng thái mới',
      (tester) async {
    final taps = <(int, bool)>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      theme: AppTheme.light(),
      home: Scaffold(
        body: MarkdownPreview(
          data: '- [x] một\n- [ ] hai\n',
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
          onToggleChecklist: (i, v) => taps.add((i, v)),
        ),
      ),
    ));

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.tap(find.byType(Checkbox).at(0));

    expect(taps, [(1, true), (0, false)]);
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

  testWidgets('link .md tương đối gọi onOpenNote với tên file, link web thì '
      'không', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      theme: AppTheme.light(),
      home: Scaffold(
        body: MarkdownPreview(
          data: '[B](./ghi%20chu.md#muc)',
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
          onOpenNote: opened.add,
        ),
      ),
    ));

    final md = tester.widget<Markdown>(find.byType(Markdown));
    md.onTapLink!('B', './ghi%20chu.md#muc', '');
    md.onTapLink!('Web', 'mailto:a@b.md', '');
    await tester.pumpAndSettle();

    expect(opened, ['ghi chu.md']);
  });

  testWidgets('cỡ chữ đoạn văn và tiêu đề theo cài đặt', (tester) async {
    await _pump(tester, '# Tiêu đề\n\nXin chào', size: 20);

    final sheet = tester.widget<Markdown>(find.byType(Markdown)).styleSheet!;
    expect(sheet.p!.fontSize, 20);
    expect(sheet.h1!.fontSize, greaterThan(20));
  });
}
