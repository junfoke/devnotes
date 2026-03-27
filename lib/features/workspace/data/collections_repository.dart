import 'dart:convert';
import 'dart:io';
import 'package:devnotes/features/workspace/domain/collection.dart';

class CollectionsRepository {
  final String storagePath;

  CollectionsRepository({required this.storagePath});

  Future<List<Collection>> loadCollections() async {
    final file = File(storagePath);
    if (!file.existsSync()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Collection.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCollections(List<Collection> collections) async {
    final file = File(storagePath);
    final json = jsonEncode(collections.map((c) => c.toJson()).toList());
    await file.writeAsString(json);
  }
}
