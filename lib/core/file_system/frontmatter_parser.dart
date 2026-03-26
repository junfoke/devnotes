// lib/core/file_system/frontmatter_parser.dart
import 'package:yaml/yaml.dart';

class ParsedNote {
  final String title;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String content;

  const ParsedNote({
    required this.title,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
  });
}

class FrontmatterParser {
  static final _frontmatterRegex = RegExp(r'^---\s*\n([\s\S]*?)\n---\s*\n?');

  static ParsedNote parse(String raw) {
    final match = _frontmatterRegex.firstMatch(raw);
    if (match == null) {
      return ParsedNote(
        title: '',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: raw,
      );
    }

    final yamlStr = match.group(1)!;
    final content = raw.substring(match.end).trim();
    final yaml = loadYaml(yamlStr) as YamlMap;

    final title = (yaml['title'] as String?) ?? '';
    final tags = yaml['tags'] != null
        ? List<String>.from(yaml['tags'] as YamlList)
        : <String>[];
    final createdAt = DateTime.parse(yaml['createdAt'] as String);
    final updatedAt = DateTime.parse(yaml['updatedAt'] as String);

    return ParsedNote(
      title: title,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      content: content,
    );
  }

  static String serialize({
    required String title,
    required List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String content,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('title: "$title"');
    if (tags.isEmpty) {
      buffer.writeln('tags: []');
    } else {
      buffer.writeln('tags:');
      for (final tag in tags) {
        buffer.writeln('- "$tag"');
      }
    }
    buffer.writeln('createdAt: "${createdAt.toUtc().toIso8601String()}"');
    buffer.writeln('updatedAt: "${updatedAt.toUtc().toIso8601String()}"');
    buffer.writeln('---');
    buffer.writeln();
    buffer.write(content);
    return buffer.toString();
  }
}
