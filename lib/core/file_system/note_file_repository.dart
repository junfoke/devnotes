// lib/core/file_system/note_file_repository.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:devnotes/core/file_system/frontmatter_parser.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';

class NoteFileRepository {
  NoteFileRepository({required this.workspacePath});

  final String workspacePath;

  /// Converts a title to a safe lowercase filename (without extension).
  String _sanitizeFileName(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  /// Generates a unique .md file path inside [workspacePath].
  /// Appends a counter suffix if a file with that name already exists.
  String _uniqueFilePath(String title) {
    final base = _sanitizeFileName(title);
    var candidate = p.join(workspacePath, '$base.md');
    if (!File(candidate).existsSync()) return candidate;

    var counter = 1;
    while (true) {
      candidate = p.join(workspacePath, '$base-$counter.md');
      if (!File(candidate).existsSync()) return candidate;
      counter++;
    }
  }

  /// Creates a new note file with YAML frontmatter and returns a [NoteFile].
  Future<NoteFile> createNote({
    required String title,
    required List<String> tags,
  }) async {
    final now = DateTime.now().toUtc();
    final filePath = _uniqueFilePath(title);

    final raw = FrontmatterParser.serialize(
      title: title,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      content: '',
    );

    await File(filePath).writeAsString(raw);

    return NoteFile(
      filePath: filePath,
      title: title,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.idle,
      content: '',
    );
  }

  /// Lists all .md files in [workspacePath], sorted by [updatedAt] descending.
  Future<List<NoteFile>> listNotes() async {
    final dir = Directory(workspacePath);
    final mdFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();

    final notes = <NoteFile>[];
    for (final file in mdFiles) {
      final note = await readNote(file.path);
      notes.add(note);
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  /// Reads and parses a single .md file at [filePath].
  Future<NoteFile> readNote(String filePath) async {
    final raw = await File(filePath).readAsString();
    final parsed = FrontmatterParser.parse(raw);

    return NoteFile(
      filePath: filePath,
      title: parsed.title,
      tags: parsed.tags,
      createdAt: parsed.createdAt,
      updatedAt: parsed.updatedAt,
      syncStatus: SyncStatus.idle,
      content: parsed.content,
    );
  }

  /// Serializes and writes [note] back to disk, updating [updatedAt].
  Future<void> saveNote(NoteFile note) async {
    final now = DateTime.now().toUtc();
    final raw = FrontmatterParser.serialize(
      title: note.title,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: now,
      content: note.content,
    );
    await File(note.filePath).writeAsString(raw);
  }

  /// Deletes the file at [filePath].
  Future<void> deleteNote(String filePath) async {
    await File(filePath).delete();
  }

  /// Renames a note: reads the old file, creates a new file with [newTitle],
  /// then deletes the old file. Returns the new [NoteFile].
  Future<NoteFile> renameNote(String oldPath, String newTitle) async {
    final old = await readNote(oldPath);
    final now = DateTime.now().toUtc();
    final newFilePath = _uniqueFilePath(newTitle);

    final raw = FrontmatterParser.serialize(
      title: newTitle,
      tags: old.tags,
      createdAt: old.createdAt,
      updatedAt: now,
      content: old.content,
    );

    await File(newFilePath).writeAsString(raw);
    await File(oldPath).delete();

    return NoteFile(
      filePath: newFilePath,
      title: newTitle,
      tags: old.tags,
      createdAt: old.createdAt,
      updatedAt: now,
      syncStatus: SyncStatus.idle,
      content: old.content,
    );
  }
}
