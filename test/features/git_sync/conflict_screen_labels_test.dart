// Nhãn hai phía ở màn conflict phải nói đúng bản nào là của ai (B-19).
//
// Khi chuyển branch master → main, "ours" là main còn bản ghi chú user vẫn
// dùng nằm ở master. Nhãn cứng "LOCAL (yours)" / "REMOTE (theirs)" khiến user
// dễ chọn nhầm bản.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/git_sync/presentation/conflict_screen.dart';

void main() {
  late Directory tmp;
  late String filePath;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('devnotes_conflict_ui_');
    filePath = '${tmp.path}/a.md';
    File(filePath).writeAsStringSync(
        '<<<<<<< HEAD\nbản main\n=======\nbản master\n>>>>>>> abc\n');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester, Widget screen) async {
    // Màn đọc file thật trong initState — dựng widget trong runAsync để lệnh
    // đọc chạy trên đồng hồ thật, nếu không nó không bao giờ xong.
    await tester.runAsync(() async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('khi chuyển branch, nhãn và nút ghi tên hai branch',
      (tester) async {
    await pump(
      tester,
      ConflictScreen(filePath: filePath, oursName: 'main', theirsName: 'master'),
    );

    expect(find.text('BẢN TRÊN MAIN'), findsOneWidget);
    expect(find.text('BẢN TRÊN MASTER'), findsOneWidget);
    expect(find.text('Giữ bản main'), findsOneWidget);
    expect(find.text('Giữ bản master'), findsOneWidget);
  });

  testWidgets('sau pull, mặc định là "máy này" và "remote"', (tester) async {
    await pump(tester, ConflictScreen(filePath: filePath));

    expect(find.text('Giữ bản máy này'), findsOneWidget);
    expect(find.text('Giữ bản remote'), findsOneWidget);
  });

  test('location giữ tên hai phía qua query, đường dẫn mã hóa một lần', () {
    final loc = ConflictScreen.location('/data/w/ghi chú.md',
        ours: 'main', theirs: 'master');
    final rawSegment = loc.split('?').first.substring('/conflict/'.length);

    expect(Uri.decodeComponent(rawSegment), '/data/w/ghi chú.md');
    expect(Uri.parse(loc).queryParameters, {'ours': 'main', 'theirs': 'master'});
  });
}
