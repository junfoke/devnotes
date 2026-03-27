import 'package:sqlite3/sqlite3.dart';

class SearchResult {
  final String filePath;
  final String title;
  final String snippet;

  const SearchResult({
    required this.filePath,
    required this.title,
    required this.snippet,
  });
}

class SearchEngine {
  final Database _db;
  bool _closed = false;

  SearchEngine({required String dbPath}) : _db = sqlite3.open(dbPath) {
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        title,
        tags,
        content,
        file_path UNINDEXED
      )
    ''');
  }

  void _ensureOpen() {
    if (_closed) throw StateError('SearchEngine is closed');
  }

  void indexNote({
    required String filePath,
    required String title,
    required String tags,
    required String content,
  }) {
    _ensureOpen();
    // Remove existing entry first (upsert)
    removeNote(filePath);
    _db.execute(
      'INSERT INTO notes_fts (file_path, title, tags, content) VALUES (?, ?, ?, ?)',
      [filePath, title, tags, content],
    );
  }

  void removeNote(String filePath) {
    _ensureOpen();
    _db.execute(
      'DELETE FROM notes_fts WHERE file_path = ?',
      [filePath],
    );
  }

  List<SearchResult> search(String query, {int limit = 50}) {
    _ensureOpen();
    if (query.trim().isEmpty) return [];

    // Escape special FTS5 characters and append wildcard
    final sanitized = query.replaceAll('"', '""');
    final ftsQuery = '"$sanitized"*';

    try {
      final results = _db.select(
        '''SELECT file_path, title, snippet(notes_fts, 2, '<b>', '</b>', '...', 32) as snippet
           FROM notes_fts
           WHERE notes_fts MATCH ?
           ORDER BY rank
           LIMIT ?''',
        [ftsQuery, limit],
      );

      return results.map((row) {
        return SearchResult(
          filePath: row['file_path'] as String,
          title: row['title'] as String,
          snippet: row['snippet'] as String,
        );
      }).toList();
    } on SqliteException {
      return [];
    }
  }

  void rebuildIndex(List<Map<String, String>> notes) {
    _ensureOpen();
    _db.execute('BEGIN');
    try {
      _db.execute('DELETE FROM notes_fts');
      for (final note in notes) {
        _db.execute(
          'INSERT INTO notes_fts (file_path, title, tags, content) VALUES (?, ?, ?, ?)',
          [note['filePath']!, note['title']!, note['tags']!, note['content']!],
        );
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _db.dispose();
  }
}
