// AC-traceability widget tests cho dialog tạo/đổi tên ghi chú.
//   - UC-001 AC-3: tiêu đề rỗng -> hiện thông báo lỗi, không đóng dialog
//   - UC-002 AC-3: tiêu đề rỗng khi đổi tên -> hiện thông báo lỗi
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#workspace--quản-lý-ghi-chú
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/presentation/widgets/create_note_dialog.dart';
import 'package:devnotes/features/workspace/presentation/widgets/rename_note_dialog.dart';
import 'package:devnotes/l10n/app_localizations.dart';

/// Mở [dialog] trong một app tối giản để test tương tác.
Future<void> _pumpDialog(WidgetTester tester, Widget dialog) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<Object?>(
            context: context,
            builder: (_) => dialog,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('UC-001 Create Note', () {
    testWidgets('AC-3: tiêu đề rỗng hiện lỗi và không đóng dialog',
        (tester) async {
      await _pumpDialog(tester, const CreateNoteDialog());

      expect(find.text('Vui lòng nhập tiêu đề'), findsNothing);

      await tester.tap(find.text('Tạo'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
      expect(find.byType(CreateNoteDialog), findsOneWidget); // vẫn mở
    });

    testWidgets('AC-3: tiêu đề chỉ có khoảng trắng cũng bị từ chối',
        (tester) async {
      await _pumpDialog(tester, const CreateNoteDialog());

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.tap(find.text('Tạo'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
      expect(find.byType(CreateNoteDialog), findsOneWidget);
    });

    testWidgets('AC-1: tiêu đề hợp lệ đóng dialog và không hiện lỗi',
        (tester) async {
      await _pumpDialog(tester, const CreateNoteDialog());

      await tester.enterText(find.byType(TextField).first, 'Ghi chú họp');
      await tester.tap(find.text('Tạo'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateNoteDialog), findsNothing);
      expect(find.text('Vui lòng nhập tiêu đề'), findsNothing);
    });

    testWidgets('lỗi biến mất khi user bắt đầu gõ lại', (tester) async {
      await _pumpDialog(tester, const CreateNoteDialog());

      await tester.tap(find.text('Tạo'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'A');
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tiêu đề'), findsNothing);
    });
  });

  group('UC-002 Rename Note', () {
    testWidgets('AC-3: tiêu đề rỗng hiện lỗi và không đóng dialog',
        (tester) async {
      await _pumpDialog(
        tester,
        const RenameNoteDialog(currentTitle: 'Ghi chú cũ'),
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Đổi tên'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
      expect(find.byType(RenameNoteDialog), findsOneWidget);
    });

    testWidgets('AC-2: tiêu đề không đổi hiện lỗi riêng', (tester) async {
      await _pumpDialog(
        tester,
        const RenameNoteDialog(currentTitle: 'Ghi chú cũ'),
      );

      await tester.tap(find.text('Đổi tên'));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu đề mới phải khác tiêu đề hiện tại'), findsOneWidget);
      expect(find.byType(RenameNoteDialog), findsOneWidget);
    });

    testWidgets('AC-1: tiêu đề mới hợp lệ đóng dialog', (tester) async {
      await _pumpDialog(
        tester,
        const RenameNoteDialog(currentTitle: 'Ghi chú cũ'),
      );

      await tester.enterText(find.byType(TextField), 'Ghi chú mới');
      await tester.tap(find.text('Đổi tên'));
      await tester.pumpAndSettle();

      expect(find.byType(RenameNoteDialog), findsNothing);
    });
  });
}
