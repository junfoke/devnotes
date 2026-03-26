import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// A named grouping of [NoteFile]s shown in the workspace sidebar.
class Collection extends Equatable {
  const Collection({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.sortOrder = 0,
  });

  /// Unique identifier for this collection.
  final String id;

  /// Display name shown in the sidebar.
  final String name;

  /// Icon representing the collection.
  final IconData icon;

  /// Accent colour used for the collection badge.
  final Color color;

  /// Position in the sidebar list (lower = higher in the list).
  final int sortOrder;

  @override
  List<Object?> get props => [id];

  Collection copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    int? sortOrder,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Serialise to a JSON-compatible map.
  ///
  /// [IconData] is stored as [IconData.codePoint] (int).
  /// [Color] is stored as [Color.toARGB32()] (int).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'color': color.toARGB32(),
      'sortOrder': sortOrder,
    };
  }

  /// Deserialise from a JSON-compatible map produced by [toJson].
  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(
        json['icon'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      color: Color(json['color'] as int),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
