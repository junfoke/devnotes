import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';

void main() {
  late SearchEngine engine;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_search_test_');
    engine = SearchEngine(dbPath: '${tempDir.path}/search.db');
  });

  tearDown(() {
    engine.close();
    tempDir.deleteSync(recursive: true);
  });

  group('SearchEngine', () {
    test('indexNote and search returns matching results', () {
      engine.indexNote(
        filePath: '/notes/flutter.md',
        title: 'Getting Started with Flutter',
        tags: 'flutter, dart',
        content: 'Flutter is Google UI toolkit for building apps.',
      );
      engine.indexNote(
        filePath: '/notes/react.md',
        title: 'React Basics',
        tags: 'react, javascript',
        content: 'React is a JavaScript library for building UIs.',
      );

      final results = engine.search('Flutter');
      expect(results.length, 1);
      expect(results[0].filePath, '/notes/flutter.md');
    });

    test('search returns snippet with highlight', () {
      engine.indexNote(
        filePath: '/notes/test.md',
        title: 'Test Note',
        tags: 'test',
        content: 'This is a test note about searching functionality.',
      );

      final results = engine.search('searching');
      expect(results.length, 1);
      expect(results[0].snippet, contains('searching'));
    });

    test('removeNote removes from index', () {
      engine.indexNote(
        filePath: '/notes/delete.md',
        title: 'Delete Me',
        tags: '',
        content: 'Unique content xyz123.',
      );

      engine.removeNote('/notes/delete.md');
      final results = engine.search('xyz123');
      expect(results, isEmpty);
    });

    test('search with no results returns empty', () {
      final results = engine.search('nonexistent_term_xyz');
      expect(results, isEmpty);
    });

    test('updateNote reindexes', () {
      engine.indexNote(
        filePath: '/notes/update.md',
        title: 'Original',
        tags: '',
        content: 'Original content.',
      );
      engine.indexNote(
        filePath: '/notes/update.md',
        title: 'Updated',
        tags: 'new',
        content: 'Updated content.',
      );

      final results = engine.search('Updated');
      expect(results.length, 1);
      expect(results[0].title, 'Updated');

      final oldResults = engine.search('Original');
      expect(oldResults, isEmpty);
    });

    test('search with double-quote in query does not throw', () {
      engine.indexNote(
        filePath: '/notes/quotes.md',
        title: 'Quoted Note',
        tags: '',
        content: 'He said hello world.',
      );
      expect(() => engine.search('He said "hello"'), returnsNormally);
    });

    test('search with whitespace-only query returns empty', () {
      final results = engine.search('   ');
      expect(results, isEmpty);
    });

    test('rebuildIndex replaces all entries', () {
      engine.indexNote(
        filePath: '/notes/old.md',
        title: 'Old Note',
        tags: '',
        content: 'Old content stale.',
      );

      engine.rebuildIndex([
        {
          'filePath': '/notes/new.md',
          'title': 'New Note',
          'tags': 'fresh',
          'content': 'Fresh new content.',
        },
      ]);

      final oldResults = engine.search('stale');
      expect(oldResults, isEmpty);

      final newResults = engine.search('Fresh');
      expect(newResults.length, 1);
      expect(newResults[0].filePath, '/notes/new.md');
    });
  });
}
