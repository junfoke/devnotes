import 'package:equatable/equatable.dart';
import 'package:devnotes/core/utils/enums.dart';

/// Represents a single Markdown note file on the filesystem.
class NoteFile extends Equatable {
  const NoteFile({
    required this.filePath,
    required this.title,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.content,
    this.conflictRef,
    this.collectionId,
  });

  /// Absolute path to the file on the local filesystem.
  final String filePath;

  /// Derived display title of the note.
  final String title;

  /// Tags associated with the note.
  final List<String> tags;

  /// Timestamp when the note was created.
  final DateTime createdAt;

  /// Timestamp of the last update.
  final DateTime updatedAt;

  /// Sync status of this note.
  final SyncStatus syncStatus;

  /// The Markdown body of the note (without frontmatter).
  final String content;

  /// Reference to a conflicting version, if any.
  final String? conflictRef;

  /// ID of the [Collection] this note belongs to, or null if uncategorised.
  final String? collectionId;

  /// Equality is based solely on [filePath] — the canonical identity of a note.
  @override
  List<Object?> get props => [filePath];

  NoteFile copyWith({
    String? filePath,
    String? title,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? content,
    Object? conflictRef = _sentinel,
    Object? collectionId = _sentinel,
  }) {
    return NoteFile(
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      content: content ?? this.content,
      conflictRef: conflictRef == _sentinel
          ? this.conflictRef
          : conflictRef as String?,
      collectionId: collectionId == _sentinel
          ? this.collectionId
          : collectionId as String?,
    );
  }
}

/// Sentinel object used to distinguish "not provided" from explicit null.
const Object _sentinel = Object();
