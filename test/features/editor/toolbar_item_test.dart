// AC-traceability tests for the Markdown toolbar model.
// Logic chèn cú pháp (_insertSyntax) nằm trong widget private; ở mức unit
// ta bảo vệ các bất biến của ToolbarItem.allItems mà flow UC-009 phụ thuộc:
// đủ 16 mục, id duy nhất, cờ isBlock đúng, cú pháp inline có insertAfter.
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#editor, specs/entities/entity-model.md (#13)
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/editor/domain/toolbar_item.dart';

void main() {
  group('UC-009 Markdown Toolbar — ToolbarItem.allItems invariants', () {
    test('exposes the 16 predefined items with unique ids', () {
      final ids = ToolbarItem.allItems.map((e) => e.id).toList();
      expect(ToolbarItem.allItems.length, 16);
      expect(ids.toSet().length, 16, reason: 'id phải duy nhất');
    });

    // Block items (heading/code block/list/quote/table/hr) phải có isBlock=true
    test('block-level items are flagged isBlock=true', () {
      const blockIds = {
        'h1', 'h2', 'h3', 'code_block', 'checklist',
        'list_unordered', 'list_ordered', 'quote', 'table', 'hr',
      };
      for (final item in ToolbarItem.allItems) {
        if (blockIds.contains(item.id)) {
          expect(item.isBlock, isTrue, reason: '${item.id} phải là block');
        }
      }
    });

    // Cú pháp bao quanh (inline) phải có cả prefix lẫn suffix để bọc vùng chọn
    test('inline wrapping items define both insertBefore and insertAfter', () {
      const wrapping = {'bold', 'italic', 'strikethrough', 'code_inline', 'link'};
      for (final item in ToolbarItem.allItems.where((e) => wrapping.contains(e.id))) {
        expect(item.insertBefore.isNotEmpty, isTrue);
        expect(item.insertAfter.isNotEmpty, isTrue,
            reason: '${item.id} cần insertAfter để bọc text');
      }
    });

    test('bold wraps selection with double asterisks', () {
      final bold = ToolbarItem.allItems.firstWhere((e) => e.id == 'bold');
      expect(bold.insertBefore, '**');
      expect(bold.insertAfter, '**');
      expect(bold.isBlock, isFalse);
    });
  });
}
