enum BlockType { clean, conflict }

enum Resolution { keepMine, keepTheirs, keepBoth }

class ConflictBlock {
  final BlockType type;
  final String content;
  final String? localContent;
  final String? remoteContent;

  const ConflictBlock.clean(this.content)
      : type = BlockType.clean,
        localContent = null,
        remoteContent = null;

  const ConflictBlock.conflict({
    required this.localContent,
    required this.remoteContent,
  })  : type = BlockType.conflict,
        content = '';
}

class ConflictParser {
  static final _conflictRegex = RegExp(
    r'<{7} .*\n([\s\S]*?)={7}\n([\s\S]*?)>{7} .*',
  );

  /// Nội dung còn ít nhất một khối `<<<<<<< … >>>>>>>` chưa giải quyết.
  static bool hasConflicts(String content) =>
      _conflictRegex.hasMatch(content);

  static List<ConflictBlock> parse(String content) {
    final blocks = <ConflictBlock>[];
    int lastEnd = 0;

    for (final match in _conflictRegex.allMatches(content)) {
      if (match.start > lastEnd) {
        final clean = content.substring(lastEnd, match.start).trim();
        if (clean.isNotEmpty) {
          blocks.add(ConflictBlock.clean(clean));
        }
      }

      blocks.add(ConflictBlock.conflict(
        localContent: match.group(1)!.trim(),
        remoteContent: match.group(2)!.trim(),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      final clean = content.substring(lastEnd).trim();
      if (clean.isNotEmpty) {
        blocks.add(ConflictBlock.clean(clean));
      }
    }

    return blocks;
  }

  static String resolveAll(String content, Resolution resolution) {
    return content.replaceAllMapped(_conflictRegex, (match) {
      final local = match.group(1)!.trim();
      final remote = match.group(2)!.trim();
      switch (resolution) {
        case Resolution.keepMine:
          return local;
        case Resolution.keepTheirs:
          return remote;
        case Resolution.keepBoth:
          return '$local\n$remote';
      }
    });
  }
}
