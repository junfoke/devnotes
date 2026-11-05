// AC-traceability tests for SearchEngine.
// Bổ sung AC chưa được bảo vệ: tìm kiếm prefix-wildcard và giới hạn 50 kết quả.
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#workspace--quản-lý-ghi-chú (tìm kiếm)
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';

void main() {
  late SearchEngine engine;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_search_ac_');
    engine = SearchEngine(dbPath: '${tempDir.path}/search.db');
  });

  tearDown(() {
    engine.close();
    tempDir.deleteSync(recursive: true);
  });

  group('UC-005 Search Notes', () {
    // AC-1: tìm theo prefix (gõ "flut" khớp "Flutter")
    test('AC-1: matches by prefix wildcard', () {
      engine.indexNote(
        filePath: '/notes/flutter.md',
        title: 'Getting Started with Flutter',
        tags: 'flutter',
        content: 'Flutter is a UI toolkit.',
      );

      final results = engine.search('flut');

      expect(results.length, 1);
      expect(results.single.filePath, '/notes/flutter.md');
    });

    // AC-3: tối đa 50 kết quả dù có nhiều hơn khớp
    test('AC-3: caps results at 50', () {
      for (var i = 0; i < 60; i++) {
        engine.indexNote(
          filePath: '/notes/note_$i.md',
          title: 'Meeting note $i',
          tags: 'work',
          content: 'Shared keyword zebra appears in every note.',
        );
      }

      final results = engine.search('zebra');

      expect(results.length, 50);
    });
  });
}
