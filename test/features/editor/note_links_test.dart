// Link giữa các note: dạng `[Tiêu đề](ten-file.md)` và việc tự sửa link khi
// đổi tên note. Hàm sửa link đụng vào nội dung NHIỀU file của user, nên chỉ
// được đổi đúng đích link — xem DECISIONS.md, "Link giữa các note và tự sửa
// link khi đổi tên" (2026-10-25).
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/editor/domain/note_links.dart';

void main() {
  group('rewriteNoteLinks', () {
    test('đổi đúng đích link, giữ ./ và #anchor', () {
      expect(
        rewriteNoteLinks(
          '[A](./a.md#x) [B](b.md)',
          from: 'a.md',
          to: 'a-moi.md',
        ),
        '[A](./a-moi.md#x) [B](b.md)',
      );
    });

    test('không đụng link trong khối code và chữ trùng tên', () {
      const s = 'a.md\n```\n[A](a.md)\n```\n[A](a.md)';
      expect(
        rewriteNoteLinks(s, from: 'a.md', to: 'z.md'),
        'a.md\n```\n[A](a.md)\n```\n[A](z.md)',
      );
    });

    test('tên file có khoảng trắng mã hóa %20 vẫn nhận ra', () {
      expect(
        rewriteNoteLinks(
          '[A](ghi%20chu.md)',
          from: 'ghi chu.md',
          to: 'ghi-chu.md',
        ),
        '[A](ghi-chu.md)',
      );
    });

    test('tên mới có khoảng trắng thì được mã hóa %20', () {
      expect(
        rewriteNoteLinks('[A](a.md)', from: 'a.md', to: 'ghi chu.md'),
        '[A](ghi%20chu.md)',
      );
    });

    test(
      'nhiều link trên một dòng đều được sửa, link note khác giữ nguyên',
      () {
        expect(
          rewriteNoteLinks(
            '[1](a.md), [2](b.md) và [3](./a.md)',
            from: 'a.md',
            to: 'c.md',
          ),
          '[1](c.md), [2](b.md) và [3](./c.md)',
        );
      },
    );

    test('tiêu đề link có ngoặc vuông (escape hoặc lồng nhau) vẫn nhận ra', () {
      expect(
        rewriteNoteLinks(
          r'[x \[y\]](a.md) [p [q] r](a.md)',
          from: 'a.md',
          to: 'b.md',
        ),
        r'[x \[y\]](b.md) [p [q] r](b.md)',
      );
    });

    test('không đụng code trong dòng', () {
      expect(
        rewriteNoteLinks(
          '`[A](a.md)` [A](a.md) ``x [A](a.md)``',
          from: 'a.md',
          to: 'b.md',
        ),
        '`[A](a.md)` [A](b.md) ``x [A](a.md)``',
      );
    });

    test('khối code ~~~ và khối code chưa đóng không bị sửa', () {
      const s = '~~~\n[A](a.md)\n~~~\n[A](a.md)\n```js\n[A](a.md)';
      expect(
        rewriteNoteLinks(s, from: 'a.md', to: 'b.md'),
        '~~~\n[A](a.md)\n~~~\n[A](b.md)\n```js\n[A](a.md)',
      );
    });

    test('fence ``` không đóng khối ~~~', () {
      const s = '~~~\n```\n[A](a.md)\n~~~\n[A](a.md)';
      expect(
        rewriteNoteLinks(s, from: 'a.md', to: 'b.md'),
        '~~~\n```\n[A](a.md)\n~~~\n[A](b.md)',
      );
    });

    test('chữ trùng tên ngoài link và link https không bị đụng', () {
      const s = 'Xem a.md hoặc (a.md) hoặc ](a.md) hoặc [x](https://h.vn/a.md)';
      expect(rewriteNoteLinks(s, from: 'a.md', to: 'b.md'), s);
    });

    test('tên file chỉ trùng phần đuôi không bị đụng', () {
      const s = '[A](xa.md) [B](a.md.md) [C](sub/a.md)';
      expect(rewriteNoteLinks(s, from: 'a.md', to: 'b.md'), s);
    });

    test('giữ title của link và dạng <...>', () {
      expect(
        rewriteNoteLinks(
          '[A](a.md "Tiêu đề") [B](<a.md>)',
          from: 'a.md',
          to: 'b.md',
        ),
        '[A](b.md "Tiêu đề") [B](<b.md>)',
      );
    });

    test('giữ nguyên xuống dòng CRLF', () {
      expect(
        rewriteNoteLinks('x\r\n[A](a.md)\r\n', from: 'a.md', to: 'b.md'),
        'x\r\n[A](b.md)\r\n',
      );
    });

    test('không có link tới note thì trả về đúng chuỗi cũ', () {
      const s = '# Tiêu đề\n\n[B](b.md)\n';
      expect(rewriteNoteLinks(s, from: 'a.md', to: 'z.md'), s);
    });
  });

  group('rewriteNoteLinks bảo thủ với khối code', () {
    String rw(String s) => rewriteNoteLinks(s, from: 'a.md', to: 'b.md');

    test('fence trong blockquote không bị sửa', () {
      const s = '> ```\n> [A](a.md)\n> ```\n[A](a.md)';
      expect(rw(s), '> ```\n> [A](a.md)\n> ```\n[A](b.md)');
    });

    test(
      'fence thụt lề (trong danh sách, ≥4 khoảng trắng, tab) không bị sửa',
      () {
        const s =
            '- mục\n    ```\n    [A](a.md)\n    ```\n'
            '\t~~~\n\t[A](a.md)\n\t~~~\n[A](a.md)';
        expect(
          rw(s),
          '- mục\n    ```\n    [A](a.md)\n    ```\n'
          '\t~~~\n\t[A](a.md)\n\t~~~\n[A](b.md)',
        );
      },
    );

    test('khối code thụt 4 khoảng trắng / tab sau dòng trống không bị sửa', () {
      const s =
          'Đoạn\n\n    [A](a.md)\n\n    [A](a.md)\n\t[A](a.md)\n'
          'Hết [A](a.md)';
      expect(
        rw(s),
        'Đoạn\n\n    [A](a.md)\n\n    [A](a.md)\n\t[A](a.md)\n'
        'Hết [A](b.md)',
      );
    });

    test('khối code thụt lề ngay đầu file không bị sửa', () {
      expect(rw('    [A](a.md)\n'), '    [A](a.md)\n');
    });

    test(
      'dòng thụt lề nối tiếp đoạn văn (không sau dòng trống) vẫn được sửa',
      () {
        expect(rw('Đoạn\n    [A](a.md)'), 'Đoạn\n    [A](b.md)');
      },
    );
  });

  group('linkedNoteFileName', () {
    test('link https và link không phải .md không phải link note', () {
      expect(linkedNoteFileName('https://x.com/a.md'), isNull);
      expect(linkedNoteFileName('img.png'), isNull);
      expect(linkedNoteFileName('./a.md#h'), 'a.md');
    });

    test(
      'giải mã %XX, bỏ ./ ; anchor trong cùng note không phải link note',
      () {
        expect(linkedNoteFileName('ghi%20chu.md'), 'ghi chu.md');
        expect(linkedNoteFileName('#muc-1'), isNull);
        expect(linkedNoteFileName('mailto:a@b.md'), isNull);
        expect(linkedNoteFileName('/tuyet-doi.md'), isNull);
        expect(linkedNoteFileName(''), isNull);
      },
    );
  });

  group('noteLink', () {
    test('escape ngoặc vuông trong tiêu đề, mã hóa khoảng trắng tên file', () {
      expect(noteLink('Ghi chú', 'ghi-chu.md'), '[Ghi chú](ghi-chu.md)');
      expect(noteLink('a [b]', 'ghi chu.md'), r'[a \[b\]](ghi%20chu.md)');
    });

    test('link vừa tạo được linkedNoteFileName đọc ngược đúng tên file', () {
      final link = noteLink('X', 'ghi chu (1).md');
      final href = link.substring(link.indexOf('](') + 2, link.length - 1);
      expect(linkedNoteFileName(href), 'ghi chu (1).md');
      expect(
        rewriteNoteLinks(link, from: 'ghi chu (1).md', to: 'y.md'),
        '[X](y.md)',
      );
    });
  });
}
