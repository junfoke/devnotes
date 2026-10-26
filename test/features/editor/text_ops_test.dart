import 'package:devnotes/features/editor/domain/text_ops.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _v(String text, int base, [int? extent]) => TextEditingValue(
    text: text,
    selection: TextSelection(baseOffset: base, extentOffset: extent ?? base));

void main() {
  test('thụt lề mọi dòng trong vùng chọn, vùng chọn giãn theo', () {
    final r = indentLines(_v('a\nb\nc', 0, 3));
    expect(r.text, '  a\n  b\nc');
    expect(r.selection, const TextSelection(baseOffset: 2, extentOffset: 7));
  });

  test('vùng chọn kết thúc đúng đầu dòng sau thì không thụt dòng đó', () {
    final r = indentLines(_v('a\nb\nc', 0, 2));
    expect(r.text, '  a\nb\nc');
  });

  test('lùi lề bỏ tối đa 2 dấu cách hoặc 1 tab', () {
    expect(outdentLines(_v('    a\n \tb\n\tc', 0, 12)).text, '  a\n\tb\nc');
  });

  test('lùi lề không xóa chữ khi dòng không có khoảng trắng đầu', () {
    expect(outdentLines(_v('abc', 1)).text, 'abc');
  });

  test('lùi lề kéo con trỏ lùi theo nội dung', () {
    final r = outdentLines(_v('  ab', 3));
    expect(r.text, 'ab');
    expect(r.selection.baseOffset, 1);
  });

  test('đưa dòng cuối (không có \\n) lên trên', () {
    expect(moveLines(_v('a\nb', 3), up: true).text, 'b\na');
  });

  test('đưa dòng đầu lên thì giữ nguyên', () {
    final v = _v('a\nb', 0);
    final r = moveLines(v, up: true);
    expect(r.text, 'a\nb');
    expect(r.selection, v.selection);
  });

  test('đưa dòng cuối xuống thì giữ nguyên', () {
    expect(moveLines(_v('a\nb', 3), up: false).text, 'a\nb');
  });

  test('đưa nhiều dòng xuống, vùng chọn đi theo', () {
    final r = moveLines(_v('a\nb\nc', 0, 3), up: false);
    expect(r.text, 'c\na\nb');
    expect(r.selection, const TextSelection(baseOffset: 2, extentOffset: 5));
  });

  test('nhân đôi dòng chứa con trỏ', () {
    final r = duplicateLines(_v('a\nbc', 3));
    expect(r.text, 'a\nbc\nbc');
    expect(r.selection.baseOffset, 6);
  });

  test('xóa dòng giữa, dòng cuối và dòng duy nhất', () {
    expect(deleteLines(_v('a\nb\nc', 2)).text, 'a\nc');
    expect(deleteLines(_v('a\nb\nc', 4)).text, 'a\nb');
    expect(deleteLines(_v('abc', 1)).text, '');
  });

  test('văn bản rỗng: mọi thao tác dòng không ném lỗi', () {
    final v = _v('', 0);
    expect(indentLines(v).text, '  ');
    expect(outdentLines(v).text, '');
    expect(moveLines(v, up: true).text, '');
    expect(moveLines(v, up: false).text, '');
    expect(duplicateLines(v).text, '\n');
    expect(deleteLines(v).text, '');
  });

  test('chèn tại con trỏ thay vùng chọn', () {
    final r = insertAtCursor(_v('abcd', 1, 3), 'X');
    expect(r.text, 'aXd');
    expect(r.selection, const TextSelection.collapsed(offset: 2));
  });

  test('chèn dạng khối tự thêm xuống dòng khi không ở đầu dòng', () {
    expect(insertAtCursor(_v('ab', 2), '---', asBlock: true).text, 'ab\n---');
    expect(insertAtCursor(_v('ab\n', 3), '---', asBlock: true).text, 'ab\n---');
  });

  // Chèn bảng / khối code giữa dòng: phần chữ còn lại phải xuống dòng mới,
  // không dính vào hàng cuối bảng hay dấu ``` đóng khối (hỏng Markdown).
  test('chèn dạng khối giữa dòng đẩy phần chữ sau xuống dòng mới', () {
    final v = insertAtCursor(_v('ab cd', 2), '```\n\n```', asBlock: true);
    expect(v.text, 'ab\n```\n\n```\n cd');
    // Con trỏ ngay sau khối, trước dấu xuống dòng tự thêm.
    expect(v.selection.baseOffset, 'ab\n```\n\n```'.length);
    expect(insertAtCursor(_v('ab\ncd', 3), 'X', asBlock: true).text,
        'ab\nX\ncd');
  });

  test('tìm theo nghĩa đen với ký tự đặc biệt', () {
    expect(findAll('a.b a*b (x)', '.').length, 1);
    expect(findAll('a.b a*b (x)', '(x)').single,
        const TextRange(start: 8, end: 11));
  });

  test('tìm không phân biệt hoa thường với chữ có dấu', () {
    expect(findAll('Ghi Chú và ghi chú', 'ghi chú').length, 2);
  });

  test('tìm phân biệt hoa thường khi được yêu cầu, chuỗi rỗng không khớp', () {
    expect(findAll('Aa', 'a', caseSensitive: true).length, 1);
    expect(findAll('Aa', ''), isEmpty);
  });

  test('thay hết bằng chuỗi rỗng', () {
    expect(replaceAllLiteral('x-y-z', '-', ''), 'xyz');
  });

  test('thay hết không hiểu \$1 hay regex trong chuỗi thay', () {
    expect(replaceAllLiteral('a.b', '.', r'$1'), r'a$1b');
  });

  test('tiêu đề trong khối code bị bỏ qua', () {
    expect(headings('# A\n```\n# không\n```\n## B').map((h) => h.title),
        ['A', 'B']);
  });

  test('tiêu đề có cấp và vị trí đầu dòng', () {
    final h = headings('x\n### Ba');
    expect(h.single.level, 3);
    expect(h.single.offset, 2);
    expect(headings('#khongphai'), isEmpty);
  });

  test('thống kê: 400 từ là 2 phút đọc, rỗng là 0', () {
    final s = textStats(List.filled(400, 'a').join(' '));
    expect(s.words, 400);
    expect(s.readMinutes, 2);
    expect(textStats('').readMinutes, 0);
    expect(textStats('').words, 0);
    expect(textStats('một').readMinutes, 1);
  });

  test('bảng 3 cột 2 hàng có hàng tiêu đề và hàng phân cách', () {
    expect(buildTable(['A', 'B', 'C'], 2),
        '| A | B | C |\n| --- | --- | --- |\n|  |  |  |\n|  |  |  |');
  });

  test('khối code có ngôn ngữ', () {
    expect(buildCodeBlock('dart'), '```dart\n\n```');
  });
}
