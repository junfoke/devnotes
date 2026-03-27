import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:devnotes/features/workspace/data/collections_repository.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:path/path.dart' as p;

final collectionsRepositoryProvider = FutureProvider<CollectionsRepository>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return CollectionsRepository(storagePath: p.join(path, 'collections.json'));
});

final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final repo = await ref.watch(collectionsRepositoryProvider.future);
  return repo.loadCollections();
});
