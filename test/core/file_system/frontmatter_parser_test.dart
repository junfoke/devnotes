// test/core/file_system/frontmatter_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/file_system/frontmatter_parser.dart';

void main() {
  group('FrontmatterParser', () {
    test('parse extracts frontmatter and content', () {
      const raw = '''---
title: "Test Note"
tags: ["flutter", "dart"]
createdAt: "2026-03-26T10:00:00Z"
updatedAt: "2026-03-26T10:30:00Z"
---

# Hello World
This is content.''';

      final result = FrontmatterParser.parse(raw);
      expect(result.title, 'Test Note');
      expect(result.tags, ['flutter', 'dart']);
      expect(result.createdAt, DateTime.parse('2026-03-26T10:00:00Z'));
      expect(result.content, '# Hello World\nThis is content.');
    });

    // UC-004 BR-1: file không có frontmatter vẫn đọc được, title suy ra từ H1.
    test('parse handles file without frontmatter', () {
      const raw = '# Just Content\nNo frontmatter here.';
      final result = FrontmatterParser.parse(raw);
      expect(result.title, 'Just Content');
      expect(result.tags, isEmpty);
      expect(result.content, raw);
    });

    test('parse handles empty tags', () {
      const raw = '''---
title: "No Tags"
tags: []
createdAt: "2026-03-26T10:00:00Z"
updatedAt: "2026-03-26T10:00:00Z"
---

Content here.''';

      final result = FrontmatterParser.parse(raw);
      expect(result.tags, isEmpty);
    });

    test('serialize creates valid frontmatter string', () {
      final output = FrontmatterParser.serialize(
        title: 'My Note',
        tags: ['flutter', 'idea'],
        createdAt: DateTime.parse('2026-03-26T10:00:00Z'),
        updatedAt: DateTime.parse('2026-03-26T10:30:00Z'),
        content: '# Hello\nWorld',
      );

      expect(output, contains('title: "My Note"'));
      expect(output, contains('tags:'));
      expect(output, contains('# Hello\nWorld'));
    });

    test('roundtrip parse -> serialize -> parse', () {
      final original = FrontmatterParser.serialize(
        title: 'Roundtrip',
        tags: ['test'],
        createdAt: DateTime.parse('2026-03-26T10:00:00Z'),
        updatedAt: DateTime.parse('2026-03-26T10:00:00Z'),
        content: '# Test\nContent here.',
      );

      final parsed = FrontmatterParser.parse(original);
      expect(parsed.title, 'Roundtrip');
      expect(parsed.tags, ['test']);
      expect(parsed.content, '# Test\nContent here.');
    });
  });
}
