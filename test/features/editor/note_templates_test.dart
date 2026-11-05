import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/editor/domain/note_templates.dart';

void main() {
  test('mẫu có đủ bản tiếng Việt và tiếng Anh, cùng bộ id', () {
    expect(
      builtInTemplates('vi').map((t) => t.id),
      builtInTemplates('en').map((t) => t.id),
    );
    expect(builtInTemplates('vi').map((t) => t.id), [
      'meeting',
      'bug_report',
      'journal',
    ]);
  });

  test('vi cho bản tiếng Việt, ngôn ngữ khác cho bản tiếng Anh', () {
    expect(builtInTemplates('vi').first.title, 'Biên bản họp');
    expect(builtInTemplates('en').first.title, 'Meeting notes');
    expect(builtInTemplates('fr').first.title, 'Meeting notes');
    for (final t in [...builtInTemplates('vi'), ...builtInTemplates('en')]) {
      expect(t.body.trim(), isNotEmpty);
    }
  });
}
