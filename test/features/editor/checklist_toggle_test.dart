// Bấm ô checklist trong preview phải đổi đúng dòng tương ứng trong văn bản
// Markdown — kể cả khi trong note có khối code chứa chuỗi giống checklist.
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/editor/domain/checklist_toggle.dart';

void main() {
  test('đánh dấu ô thứ hai, các ô khác giữ nguyên', () {
    const src = '- [ ] một\n- [ ] hai\n- [x] ba\n';

    expect(toggleChecklistItem(src, 1, true),
        '- [ ] một\n- [x] hai\n- [x] ba\n');
  });

  test('bỏ đánh dấu ô đã tích (cả x hoa)', () {
    expect(toggleChecklistItem('- [X] xong\n', 0, false), '- [ ] xong\n');
  });

  test('hỗ trợ *, + và thụt lề', () {
    const src = '* [ ] a\n  + [ ] b\n';

    expect(toggleChecklistItem(src, 1, true), '* [ ] a\n  + [x] b\n');
  });

  test('bỏ qua chuỗi giống checklist nằm trong khối code', () {
    const src = '```md\n- [ ] trong code\n```\n- [ ] thật\n';

    expect(toggleChecklistItem(src, 0, true),
        '```md\n- [ ] trong code\n```\n- [x] thật\n');
  });

  test('vị trí không tồn tại thì giữ nguyên văn bản', () {
    const src = '- [ ] một\n';

    expect(toggleChecklistItem(src, 5, true), src);
  });

  test('giữ nguyên kiểu xuống dòng CRLF', () {
    const src = '- [ ] a\r\n- [ ] b\r\n';

    expect(toggleChecklistItem(src, 0, true), '- [x] a\r\n- [ ] b\r\n');
  });
}
