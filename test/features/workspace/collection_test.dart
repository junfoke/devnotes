import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';

void main() {
  group('Collection', () {
    final collection = Collection(
      id: 'col-1',
      name: 'My Notes',
      icon: Icons.folder,
      color: Colors.blue,
      sortOrder: 0,
    );

    test('creates with all fields', () {
      expect(collection.id, 'col-1');
      expect(collection.name, 'My Notes');
      expect(collection.icon, Icons.folder);
      expect(collection.color, Colors.blue);
      expect(collection.sortOrder, 0);
    });

    test('copyWith updates specified fields', () {
      final updated = collection.copyWith(name: 'Renamed');
      expect(updated.name, 'Renamed');
      expect(updated.id, collection.id);
      expect(updated.icon, collection.icon);
      expect(updated.color, collection.color);
      expect(updated.sortOrder, collection.sortOrder);
    });

    test('toJson / fromJson roundtrip', () {
      final json = collection.toJson();
      final restored = Collection.fromJson(json);

      expect(restored.id, collection.id);
      expect(restored.name, collection.name);
      expect(restored.icon.codePoint, collection.icon.codePoint);
      expect(restored.color.toARGB32(), collection.color.toARGB32());
      expect(restored.sortOrder, collection.sortOrder);
    });

    test('toJson serialises IconData as codePoint int', () {
      final json = collection.toJson();
      expect(json['icon'], isA<int>());
      expect(json['icon'], Icons.folder.codePoint);
    });

    test('toJson serialises Color as int value', () {
      final json = collection.toJson();
      expect(json['color'], isA<int>());
      expect(json['color'], Colors.blue.toARGB32());
    });

    test('equality compares all fields', () {
      final identical = Collection(
        id: 'col-1',
        name: 'My Notes',
        icon: Icons.folder,
        color: Colors.blue,
        sortOrder: 0,
      );
      expect(collection, equals(identical));

      final different = Collection(
        id: 'col-1',
        name: 'Different Name',
        icon: Icons.star,
        color: Colors.red,
        sortOrder: 99,
      );
      expect(collection, isNot(equals(different)));
    });

    test('inequality when id differs', () {
      final different = collection.copyWith(id: 'col-2');
      expect(collection, isNot(equals(different)));
    });
  });
}
