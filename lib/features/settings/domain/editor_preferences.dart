import 'package:devnotes/core/utils/enums.dart';

/// User-configurable preferences for the markdown editor.
class EditorPreferences {
  const EditorPreferences({
    this.fontSize = 16.0,
    this.fontFamily = 'JetBrainsMono',
    this.autoSaveInterval = const Duration(seconds: 5),
    this.toolbarItems = defaultToolbarItems,
    this.syncFrequency = SyncFrequency.manual,
    this.periodicInterval = const Duration(minutes: 30),
  });

  /// Font size in logical pixels used in the editor.
  final double fontSize;

  /// Font family name applied to the editor text.
  final String fontFamily;

  /// How long to wait after the last keystroke before auto-saving.
  final Duration autoSaveInterval;

  /// Ordered list of toolbar item identifiers visible in the editor toolbar.
  final List<String> toolbarItems;

  /// When automatic syncing should be triggered.
  final SyncFrequency syncFrequency;

  /// Interval between automatic syncs when [syncFrequency] is
  /// [SyncFrequency.periodic].
  final Duration periodicInterval;

  /// Default set of toolbar items shown in the editor.
  static const defaultToolbarItems = [
    'h1',
    'h2',
    'h3',
    'bold',
    'italic',
    'strikethrough',
    'link',
    'image',
    'code_inline',
    'code_block',
    'checklist',
    'list_ordered',
    'list_unordered',
    'quote',
    'table',
    'hr',
  ];

  EditorPreferences copyWith({
    double? fontSize,
    String? fontFamily,
    Duration? autoSaveInterval,
    List<String>? toolbarItems,
    SyncFrequency? syncFrequency,
    Duration? periodicInterval,
  }) {
    return EditorPreferences(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      toolbarItems: toolbarItems ?? this.toolbarItems,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      periodicInterval: periodicInterval ?? this.periodicInterval,
    );
  }
}
