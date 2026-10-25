// Tự lưu phải bắt được MỌI thay đổi nội dung, kể cả thay đổi do code sinh ra
// (thanh công cụ Markdown), không chỉ thay đổi do gõ phím.
//
// Bug B-01: MarkdownToolbar gán thẳng textController.value, việc này không kích
// hoạt TextField.onChanged nên trạng thái vẫn là "saved" và autosave không bao
// giờ chạy — cú pháp chèn từ toolbar bị mất khi thoát màn hình.
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
  late InMemoryNoteRepository repo;
  late NoteFile note;
  late ProviderContainer container;

  setUp(() {
    // Tắt tooltip onboarding để nó không phủ lên màn hình trong test.
    SharedPreferences.setMockInitialValues({'tooltip_editor': true});

    repo = InMemoryNoteRepository();
    note = repo.seed(fileName: 'ghi-chu.md', content: 'noi dung');

    container = ProviderContainer(overrides: [
      noteFileRepositoryProvider.overrideWith((ref) async => repo),
    ]);
  });

  tearDown(() => container.dispose());

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: EditorScreen(filePath: note.filePath),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Nội dung thân note đã được ghi qua repository.
  String contentOnDisk() => repo.notes[note.filePath]!.content;

  testWidgets('chèn cú pháp từ toolbar được ghi xuống file sau debounce',
      (tester) async {
    await pumpEditor(tester);
    expect(contentOnDisk(), 'noi dung');

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();

    // Chờ qua mốc debounce 3 giây rồi để tác vụ ghi file chạy xong.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(contentOnDisk(), contains('****'));
  });

  testWidgets('chèn cú pháp từ toolbar chuyển trạng thái sang unsaved ngay',
      (tester) async {
    await pumpEditor(tester);
    expect(container.read(saveStatusProvider), SaveStatus.saved);

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();

    expect(container.read(saveStatusProvider), SaveStatus.unsaved);

    // Dọn timer debounce đang treo để test không báo lỗi pending timer.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('sau debounce trạng thái quay lại saved', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(container.read(saveStatusProvider), SaveStatus.saved);
  });

  testWidgets('chỉ di chuyển con trỏ thì không đánh dấu unsaved',
      (tester) async {
    await pumpEditor(tester);

    final field = tester.widget<TextField>(find.byType(TextField).first);
    final controller = field.controller!;
    expect(controller.text, 'noi dung');

    // Đổi vùng chọn nhưng giữ nguyên nội dung — không được coi là chỉnh sửa,
    // nếu không mỗi lần chạm vào văn bản sẽ sinh một commit git rác.
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();

    expect(container.read(saveStatusProvider), SaveStatus.saved);
  });

  testWidgets('gõ phím vẫn kích hoạt tự lưu như cũ', (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'noi dung moi');
    await tester.pump();
    expect(container.read(saveStatusProvider), SaveStatus.unsaved);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(contentOnDisk(), 'noi dung moi');
  });
}
