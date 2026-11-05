// AC-traceability tests for FrontmatterParser.
//
// Bảo vệ các business rule về an toàn dữ liệu frontmatter:
//   - UC-001 BR-3: escape YAML cho title/tags (ký tự " và \)
//   - UC-004 BR-1: parse chịu lỗi — file .md thiếu/hỏng frontmatter vẫn đọc được
//
// Quyết định: DECISIONS.md — "Escape giá trị chuỗi trong YAML frontmatter",
//             "File .md thiếu hoặc hỏng frontmatter"
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/file_system/frontmatter_parser.dart';

void main() {
  final t0 = DateTime.parse('2026-03-26T10:00:00Z');

  group('UC-001 BR-3 — an toàn YAML khi serialize', () {
    test('title chứa dấu nháy kép roundtrip đúng nguyên văn', () {
      final raw = FrontmatterParser.serialize(
        title: 'Ghi chú "quan trọng"',
        tags: const [],
        createdAt: t0,
        updatedAt: t0,
        content: 'body',
      );

      final parsed = FrontmatterParser.parse(raw);
      expect(parsed.title, 'Ghi chú "quan trọng"');
      expect(parsed.content, 'body');
    });

    test('title chứa dấu gạch chéo ngược roundtrip đúng nguyên văn', () {
      final raw = FrontmatterParser.serialize(
        title: r'C:\Users\note',
        tags: const [],
        createdAt: t0,
        updatedAt: t0,
        content: 'body',
      );

      expect(FrontmatterParser.parse(raw).title, r'C:\Users\note');
    });

    test('tag chứa dấu nháy kép roundtrip đúng nguyên văn', () {
      final raw = FrontmatterParser.serialize(
        title: 'Note',
        tags: const ['a"b', r'c\d'],
        createdAt: t0,
        updatedAt: t0,
        content: '',
      );

      expect(FrontmatterParser.parse(raw).tags, ['a"b', r'c\d']);
    });
  });

  group('UC-004 BR-1 — parse chịu lỗi', () {
    test('không có frontmatter: title lấy từ heading H1', () {
      final parsed = FrontmatterParser.parse(
        '# Project Docs\n\nHello',
        fallbackTitle: 'readme',
        fallbackTimestamp: t0,
      );

      expect(parsed.title, 'Project Docs');
      expect(parsed.content, '# Project Docs\n\nHello');
      expect(parsed.createdAt, t0);
      expect(parsed.updatedAt, t0);
      expect(parsed.tags, isEmpty);
    });

    test('không có frontmatter và không có H1: title lấy từ fallbackTitle', () {
      final parsed = FrontmatterParser.parse(
        'chỉ là văn bản thường',
        fallbackTitle: 'ghi-chu-cu',
        fallbackTimestamp: t0,
      );

      expect(parsed.title, 'ghi-chu-cu');
    });

    test('frontmatter thiếu createdAt/updatedAt: dùng fallbackTimestamp', () {
      const raw = '''---
title: "Only Title"
---

body''';

      final parsed = FrontmatterParser.parse(
        raw,
        fallbackTitle: 'x',
        fallbackTimestamp: t0,
      );

      expect(parsed.title, 'Only Title');
      expect(parsed.createdAt, t0);
      expect(parsed.updatedAt, t0);
      expect(parsed.content, 'body');
    });

    test('frontmatter có YAML không hợp lệ: không ném ngoại lệ', () {
      const raw = '''---
title: "unclosed
tags: [oops
---

body''';

      expect(
        () => FrontmatterParser.parse(
          raw,
          fallbackTitle: 'broken',
          fallbackTimestamp: t0,
        ),
        returnsNormally,
      );

      final parsed = FrontmatterParser.parse(
        raw,
        fallbackTitle: 'broken',
        fallbackTimestamp: t0,
      );
      expect(parsed.title, 'broken');
      expect(parsed.createdAt, t0);
    });

    test('tags sai kiểu (chuỗi thay vì list): trả về danh sách rỗng', () {
      const raw = '''---
title: "Bad Tags"
tags: "not-a-list"
createdAt: "2026-03-26T10:00:00Z"
updatedAt: "2026-03-26T10:00:00Z"
---

body''';

      final parsed = FrontmatterParser.parse(raw, fallbackTimestamp: t0);
      expect(parsed.title, 'Bad Tags');
      expect(parsed.tags, isEmpty);
    });

    test('createdAt sai định dạng: dùng fallbackTimestamp', () {
      const raw = '''---
title: "Bad Date"
tags: []
createdAt: "hôm qua"
updatedAt: "hôm nay"
---

body''';

      final parsed = FrontmatterParser.parse(raw, fallbackTimestamp: t0);
      expect(parsed.createdAt, t0);
      expect(parsed.updatedAt, t0);
    });
  });
}
