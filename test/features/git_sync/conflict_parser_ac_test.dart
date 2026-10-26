// AC-traceability tests for conflict resolution.
// Bổ sung: chiến lược keepTheirs và quy tắc "một chiến lược cho TOÀN BỘ file"
// (nhiều khối xung đột đều được resolve cùng một lựa chọn).
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#git-sync (resolve conflict)
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/git_sync/domain/conflict_parser.dart';

void main() {
  group('UC-012 Resolve Merge Conflict', () {
    const multiConflict = '''intro line
<<<<<<< HEAD
mine A
=======
theirs A
>>>>>>> remote
middle line
<<<<<<< HEAD
mine B
=======
theirs B
>>>>>>> remote
end line''';

    // AC-1 (biến thể): giữ phiên bản remote
    test('AC-1: keepTheirs replaces every conflict with remote content', () {
      final resolved =
          ConflictParser.resolveAll(multiConflict, Resolution.keepTheirs);
      expect(resolved.contains('theirs A'), isTrue);
      expect(resolved.contains('theirs B'), isTrue);
      expect(resolved.contains('mine A'), isFalse);
      expect(resolved.contains('mine B'), isFalse);
      expect(resolved.contains('<<<<<<<'), isFalse);
    });

    // BR: một chiến lược áp dụng cho mọi khối xung đột trong cùng file
    test('applies a single strategy to ALL conflict blocks in the file', () {
      final blocks = ConflictParser.parse(multiConflict);
      final conflictCount =
          blocks.where((b) => b.type == BlockType.conflict).length;
      expect(conflictCount, 2);

      final resolved =
          ConflictParser.resolveAll(multiConflict, Resolution.keepMine);
      // sau resolve không còn marker nào
      expect(ConflictParser.parse(resolved).any((b) => b.type == BlockType.conflict),
          isFalse);
      expect(resolved.contains('mine A'), isTrue);
      expect(resolved.contains('mine B'), isTrue);
    });
  });
}
