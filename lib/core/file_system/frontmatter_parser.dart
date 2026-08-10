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
  static final _headingRegex = RegExp(r'^#\s+(.+)$', multiLine: true);

  /// Parses a raw Markdown file into a [ParsedNote].
  ///
  /// Parsing is deliberately forgiving: the workspace is a shared git repo, so
  /// `.md` files written by other people or tools may have no frontmatter at
  /// all, or an incomplete/invalid one. Such a file must still be readable
  /// rather than crashing the note list.
  /// See DECISIONS.md, "File .md thiếu hoặc hỏng frontmatter".
  ///
  /// [fallbackTitle] is used when neither the frontmatter nor a leading `# `
  /// heading supplies a title — callers pass the file name.
  /// [fallbackTimestamp] is used for missing/unparsable dates — callers pass
  /// the file's on-disk modification time.
  static ParsedNote parse(
    String raw, {
    String? fallbackTitle,
    DateTime? fallbackTimestamp,
  }) {
    final fallbackTime = fallbackTimestamp ?? DateTime.now();
    final match = _frontmatterRegex.firstMatch(raw);

    // No frontmatter block, or one whose YAML does not parse: treat the whole
    // file as content so nothing is lost, and derive the metadata.
    final YamlMap? yaml = match == null ? null : _tryLoadYaml(match.group(1)!);
    if (yaml == null) {
      return ParsedNote(
        title: _inferTitle(raw, fallbackTitle),
        tags: const [],
        createdAt: fallbackTime,
        updatedAt: fallbackTime,
        content: raw,
      );
    }

    final content = raw.substring(match!.end).trim();
    final declaredTitle = yaml['title'];
    final title = declaredTitle is String && declaredTitle.trim().isNotEmpty
        ? declaredTitle
        : _inferTitle(content, fallbackTitle);

    return ParsedNote(
      title: title,
      tags: _readTags(yaml['tags']),
      createdAt: _readDate(yaml['createdAt'], fallbackTime),
      updatedAt: _readDate(yaml['updatedAt'], fallbackTime),
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
    buffer.writeln('title: "${_escape(title)}"');
    if (tags.isEmpty) {
      buffer.writeln('tags: []');
    } else {
      buffer.writeln('tags:');
      for (final tag in tags) {
        buffer.writeln('- "${_escape(tag)}"');
      }
    }
    buffer.writeln('createdAt: "${createdAt.toUtc().toIso8601String()}"');
    buffer.writeln('updatedAt: "${updatedAt.toUtc().toIso8601String()}"');
    buffer.writeln('---');
    buffer.writeln();
    buffer.write(content);
    return buffer.toString();
  }

  /// Escapes a value for a YAML double-quoted scalar.
  /// See DECISIONS.md, "Escape giá trị chuỗi trong YAML frontmatter".
  /// Backslash must be escaped first, otherwise the backslashes this method
  /// itself introduces would be escaped again.
  static String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  static YamlMap? _tryLoadYaml(String source) {
    try {
      final loaded = loadYaml(source);
      return loaded is YamlMap ? loaded : null;
    } catch (_) {
      return null;
    }
  }

  /// Title from the first `# ` heading, else [fallbackTitle], else empty.
  static String _inferTitle(String content, String? fallbackTitle) {
    final heading = _headingRegex.firstMatch(content);
    if (heading != null) return heading.group(1)!.trim();
    return fallbackTitle ?? '';
  }

  static List<String> _readTags(Object? value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime _readDate(Object? value, DateTime fallback) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? fallback;
    return fallback;
  }
}
