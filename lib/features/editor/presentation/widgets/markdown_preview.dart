import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:highlight/languages/all.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';

/// Trang xem trước Markdown của editor.
///
/// - Cỡ chữ và font theo Settings → Font & Size (trước đây cứng 14px).
/// - Khối code ```lang được tô màu cú pháp theo ngôn ngữ.
/// - Bấm link thì mở bằng trình duyệt / app tương ứng.
class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({
    super.key,
    required this.data,
    required this.fontFamily,
    required this.fontSize,
  });

  final String data;
  final String fontFamily;
  final double fontSize;

  Future<void> _openLink(BuildContext context, String? href) async {
    final uri = href == null ? null : Uri.tryParse(href);
    var opened = false;
    if (uri != null && uri.hasScheme) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.linkOpenFailed(href ?? ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final codeStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize * 0.93,
      height: 1.5,
    );

    return Markdown(
      data: data,
      selectable: true,
      padding: const EdgeInsets.all(20),
      onTapLink: (_, href, __) => _openLink(context, href),
      builders: {
        'code': _CodeBlockBuilder(dark: dark, textStyle: codeStyle),
      },
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
            color: colors.textSecondary, fontSize: fontSize, height: 1.6),
        listBullet: TextStyle(color: colors.textSecondary, fontSize: fontSize),
        h1: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize * 1.7,
            fontWeight: FontWeight.bold),
        h2: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize * 1.4,
            fontWeight: FontWeight.bold),
        h3: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize * 1.15,
            fontWeight: FontWeight.bold),
        a: TextStyle(
            color: colors.accent, decoration: TextDecoration.underline),
        code: codeStyle.copyWith(
          color: colors.accentLight,
          backgroundColor: colors.codeBg,
        ),
        codeblockDecoration: BoxDecoration(
          color: colors.codeBg,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.border, width: 4)),
        ),
      ),
    );
  }
}

/// Tô màu khối code theo ngôn ngữ trong ```lang. Code nằm trong dòng (không
/// có class ngôn ngữ, không xuống dòng) trả về null để giữ kiểu mặc định.
class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.dark, required this.textStyle});

  final bool dark;
  final TextStyle textStyle;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final cls = element.attributes['class'];
    final source = element.textContent;
    final isBlock = cls != null || source.contains('\n');
    if (!isBlock) return null;

    final lang = cls?.replaceFirst('language-', '');
    // Ngôn ngữ lạ thì không tô màu — highlight ném lỗi với tên không biết.
    final known = lang != null && allLanguages.containsKey(lang);
    final base = dark ? atomOneDarkTheme : githubTheme;
    // Nền do codeblockDecoration lo, để theme sáng/tối của app quyết định.
    final theme = {
      ...base,
      'root': (base['root'] ?? const TextStyle())
          .copyWith(backgroundColor: Colors.transparent),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: HighlightView(
        source.trimRight(),
        language: known ? lang : 'plaintext',
        theme: theme,
        padding: EdgeInsets.zero,
        textStyle: textStyle,
      ),
    );
  }
}
