// Ghi file thất bại thì người dùng phải biết, và nội dung đang soạn không được
// mất.
//
// Bug B-13: _save() không có nhánh lỗi — ghi lỗi thì UI kẹt ở "saving" mà
// không báo gì, còn nút Back vẫn thoát màn hình và bỏ luôn nội dung chưa lưu.
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#editor
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';

import 'in_memory_note_repository.dart';

void main() {
  late NoteFile note;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({'tooltip_editor': true});

    final repo = InMemoryNoteRepository()..failOnSave = true;
    note = repo.seed(fileName: 'ghi-chu.md', content: 'noi dung');

    container = ProviderContainer(overrides: [
      noteFileRepositoryProvider.overrideWith((ref) async => repo),
    ]);
  });

  tearDown(() => container.dispose());

  /// Mở editor từ một màn hình gốc để nút Back có chỗ quay về.
  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EditorScreen(filePath: note.filePath),
                )),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('tự lưu thất bại thì báo lỗi và trạng thái về unsaved',
      (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'noi dung moi');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(container.read(saveStatusProvider), SaveStatus.unsaved);
    expect(find.textContaining('Không lưu được'), findsOneWidget);
  });

  testWidgets('bấm Back khi lưu thất bại thì ở lại editor, nội dung còn nguyên',
      (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'noi dung moi');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsOneWidget);
    expect(find.text('noi dung moi'), findsOneWidget);
    expect(find.textContaining('Không lưu được'), findsOneWidget);
  });
}
