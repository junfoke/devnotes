import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/git_sync/domain/conflict_parser.dart';

void main() {
  group('ConflictParser', () {
    test('parses conflict markers into blocks', () {
      const content = '''Some clean text
<<<<<<< HEAD
local version of the line
=======
remote version of the line
>>>>>>> remote
More clean text''';

      final blocks = ConflictParser.parse(content);
      expect(blocks.length, 3);
      expect(blocks[0].type, BlockType.clean);
      expect(blocks[0].content, 'Some clean text');
      expect(blocks[1].type, BlockType.conflict);
      expect(blocks[1].localContent, 'local version of the line');
      expect(blocks[1].remoteContent, 'remote version of the line');
      expect(blocks[2].type, BlockType.clean);
      expect(blocks[2].content, 'More clean text');
    });

    test('resolveKeepMine returns local content', () {
      const content = '''<<<<<<< HEAD
mine
=======
theirs
>>>>>>> remote''';

      final resolved = ConflictParser.resolveAll(content, Resolution.keepMine);
      expect(resolved, 'mine');
    });

    test('resolveKeepTheirs returns remote content', () {
      const content = '''<<<<<<< HEAD
mine
=======
theirs
>>>>>>> remote''';

      final resolved = ConflictParser.resolveAll(content, Resolution.keepTheirs);
      expect(resolved, 'theirs');
    });

    test('resolveKeepBoth returns both', () {
      const content = '''<<<<<<< HEAD
mine
=======
theirs
>>>>>>> remote''';

      final resolved = ConflictParser.resolveAll(content, Resolution.keepBoth);
      expect(resolved, 'mine\ntheirs');
    });
  });
}
