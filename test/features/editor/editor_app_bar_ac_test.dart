// AC-traceability widget test cho app bar của editor.
//   - UC-008 AC-3: hiển thị tiêu đề note đang mở
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#editor
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_app_bar.dart';
import 'package:devnotes/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, {required String? title}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.light(),
        home: Scaffold(
          body: EditorAppBar(
            title: title,
            saveStatus: SaveStatus.saved,
            currentPage: 0,
            onBack: () async {},
            onMore: () {},
          ),
        ),
      ),
    );
  }

  group('UC-008 Edit Note', () {
    testWidgets('AC-3: hiển thị tiêu đề note đang mở', (tester) async {
      await pumpBar(tester, title: 'Ghi chú họp');

      expect(find.text('Ghi chú họp'), findsOneWidget);
    });

    testWidgets('AC-3: tiêu đề dài bị cắt trên một dòng', (tester) async {
      const longTitle =
          'Một tiêu đề rất dài dùng để kiểm tra hành vi cắt chuỗi của app bar';
      await pumpBar(tester, title: longTitle);

      final text = tester.widget<Text>(find.text(longTitle));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('AC-3: chưa nạp xong note thì không vẽ tiêu đề rỗng',
        (tester) async {
      await pumpBar(tester, title: null);

      expect(find.byType(Text), findsNothing);
    });
  });
}
