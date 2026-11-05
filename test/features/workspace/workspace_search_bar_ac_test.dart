// AC-traceability widget test cho ô tìm kiếm workspace.
//   - UC-005 AC-4: nút xóa (X) làm trống query và thoát chế độ tìm kiếm
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#workspace--quản-lý-ghi-chú (tìm kiếm)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/presentation/widgets/workspace_search_bar.dart';
import 'package:devnotes/l10n/app_localizations.dart';

void main() {
  late TextEditingController controller;
  late List<String> emitted;

  setUp(() {
    controller = TextEditingController();
    emitted = [];
  });

  tearDown(() => controller.dispose());

  Future<void> pumpBar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.light(),
        home: Scaffold(
          body: WorkspaceSearchBar(
            controller: controller,
            onChanged: emitted.add,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  group('UC-005 Search Notes', () {
    testWidgets('AC-4: nút xóa chỉ hiện khi ô có nội dung', (tester) async {
      await pumpBar(tester);
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.enterText(find.byType(TextField), 'meet');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('AC-4: nhấn nút xóa làm trống ô và phát query rỗng',
        (tester) async {
      await pumpBar(tester);

      await tester.enterText(find.byType(TextField), 'meet');
      await tester.pumpAndSettle();
      emitted.clear();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(emitted, ['']);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
