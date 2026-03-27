import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:path/path.dart' as p;

final searchEngineProvider = FutureProvider<SearchEngine>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  final dbPath = p.join(p.dirname(path), 'search_index.db');
  final engine = SearchEngine(dbPath: dbPath);
  ref.onDispose(engine.close);
  return engine;
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final engine = await ref.watch(searchEngineProvider.future);
  return engine.search(query);
});
