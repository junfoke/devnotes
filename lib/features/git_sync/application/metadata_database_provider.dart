import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:path/path.dart' as p;

final metadataDatabaseProvider = FutureProvider<MetadataDatabase>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  final dbPath = p.join(p.dirname(path), 'metadata.db');
  final db = MetadataDatabase(dbPath: dbPath);
  ref.onDispose(db.close);
  return db;
});
