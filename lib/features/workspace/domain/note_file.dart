import 'package:equatable/equatable.dart';

/// Represents a single Markdown note file on the filesystem.
class NoteFile extends Equatable {
  const NoteFile({
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.lastModified,
    this.collectionId,
  });

  /// Absolute path to the file on the local filesystem.
  final String filePath;

  /// Base filename including extension (e.g. "hello.md").
  final String fileName;

  /// Derived display title of the note.
  final String title;

  /// Timestamp of the last filesystem modification.
  final DateTime lastModified;

  /// ID of the [Collection] this note belongs to, or null if uncategorised.
  final String? collectionId;

  /// Equality is based solely on [filePath] — the canonical identity of a note.
  @override
  List<Object?> get props => [filePath];

  NoteFile copyWith({
    String? filePath,
    String? fileName,
    String? title,
    DateTime? lastModified,
    Object? collectionId = _sentinel,
  }) {
    return NoteFile(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      lastModified: lastModified ?? this.lastModified,
      collectionId: collectionId == _sentinel
          ? this.collectionId
          : collectionId as String?,
    );
  }
}

/// Sentinel object used to distinguish "not provided" from explicit null.
const Object _sentinel = Object();
