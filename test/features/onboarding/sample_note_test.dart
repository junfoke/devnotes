// Note mẫu ở bước cuối onboarding được tạo bằng đúng ngôn ngữ giao diện.
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/onboarding/domain/sample_note.dart';

void main() {
  test('giao diện tiếng Việt thì note mẫu tiếng Việt', () {
    final note = SampleNote.forLanguage('vi');

    expect(note.title, 'Chào mừng đến với DevNotes');
    expect(note.content, startsWith('# Chào mừng đến với DevNotes!'));
  });

  test('tiếng Anh hoặc ngôn ngữ khác thì note mẫu tiếng Anh', () {
    for (final code in ['en', 'fr']) {
      final note = SampleNote.forLanguage(code);
      expect(note.title, 'Welcome to DevNotes');
      expect(note.content, startsWith('# Welcome to DevNotes!'));
    }
  });

  test('hai bản đều giữ tag getting-started và hướng dẫn Markdown', () {
    expect(SampleNote.tags, ['getting-started']);
    for (final note in [SampleNote.en, SampleNote.vi]) {
      expect(note.content, contains('```dart'));
      expect(note.content, contains('- [x]'));
    }
  });
}
