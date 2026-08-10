// Sheet lịch sử đồng bộ phải hiển thị được danh sách dài mà không tràn.
//
// Trước đây lịch sử luôn rỗng (bug B-04) nên không ai thấy sheet vỡ layout khi
// có đủ 20 bản ghi.
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#git-sync
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';
import 'package:devnotes/features/git_sync/presentation/widgets/sync_history_sheet.dart';

List<SyncLogEntry> _entries(int count) => List.generate(
      count,
      (i) => SyncLogEntry(
        timestamp: DateTime(2026, 8, 10, 12, i % 60),
        action: SyncAction.push,
        filesChanged: i,
        success: i.isEven,
        errorMessage: i.isEven
            ? null
            : 'error: git_error_t.GIT_ERROR_INVALID: Incorrect credentials.',
      ),
    );

Future<void> _pumpSheet(WidgetTester tester, List<SyncLogEntry> entries) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SyncHistorySheet(
            branchName: 'master',
            lastSyncAt: DateTime(2026, 8, 10, 12, 27),
            entries: entries,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('20 bản ghi không làm vỡ layout', (tester) async {
    await _pumpSheet(tester, _entries(20));

    // takeException() trả về lỗi overflow nếu RenderFlex tràn.
    expect(tester.takeException(), isNull);
  });

  testWidgets('danh sách dài cuộn được', (tester) async {
    await _pumpSheet(tester, _entries(20));

    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('lịch sử rỗng vẫn hiện thông báo và không tràn', (tester) async {
    await _pumpSheet(tester, const []);

    expect(find.text('No sync history yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiện tên branch và thời điểm sync gần nhất', (tester) async {
    await _pumpSheet(tester, _entries(3));

    expect(find.text('master'), findsOneWidget);
    expect(find.textContaining('Last sync'), findsOneWidget);
  });

  testWidgets('bản ghi thất bại hiện thông báo lỗi', (tester) async {
    await _pumpSheet(tester, _entries(2));

    expect(find.textContaining('Incorrect credentials'), findsOneWidget);
  });
}
