import 'package:devnotes/core/utils/enums.dart';

/// Giãn dòng của editor: hệ số nhân với cỡ chữ.
enum EditorLineHeight {
  compact(1.35),
  normal(1.6),
  relaxed(1.9);

  const EditorLineHeight(this.value);
  final double value;
}

/// User-configurable preferences for the markdown editor.
class EditorPreferences {
  const EditorPreferences({
    this.fontSize = defaultFontSize,
    this.fontFamily = 'JetBrainsMono',
    this.autoSaveInterval = defaultAutoSaveInterval,
    this.toolbarItems = defaultToolbarItems,
    this.syncFrequency = SyncFrequency.manual,
    this.periodicInterval = const Duration(minutes: 30),
    this.lineHeight = EditorLineHeight.normal,
    this.wordWrap = true,
    this.focusMode = false,
    this.hiddenTools = const [],
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

  /// Giãn dòng áp dụng cho mọi note.
  final EditorLineHeight lineHeight;

  /// Tự xuống dòng khi dòng dài hơn chiều rộng.
  final bool wordWrap;

  /// Chế độ tập trung (ẩn bớt thành phần giao diện khi soạn).
  final bool focusMode;

  /// Id các công cụ bị ẩn khỏi bảng Công cụ soạn thảo.
  final List<String> hiddenTools;

  /// Giá trị [fontFamily] nghĩa là dùng font mặc định của app.
  static const systemFont = 'system';

  /// Font dùng khi dựng TextStyle; null = font mặc định của app.
  String? get fontFamilyOrNull => fontFamily == systemFont ? null : fontFamily;

  /// Các nút được thêm vào ghim mặc định ở đợt Công cụ soạn thảo.
  static const pinnedAddedByToolsUpdate = ['undo', 'redo', 'indent', 'outdent'];

  /// Mặc định duy nhất cho cỡ chữ và khoảng chờ tự lưu — model, repository
  /// và editor đều dùng hai hằng này (trước đây mỗi nơi một số: 14/16, 3s/5s).
  static const defaultFontSize = 14.0;
  static const defaultAutoSaveInterval = Duration(seconds: 3);

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
    ...pinnedAddedByToolsUpdate,
  ];

  EditorPreferences copyWith({
    double? fontSize,
    String? fontFamily,
    Duration? autoSaveInterval,
    List<String>? toolbarItems,
    SyncFrequency? syncFrequency,
    Duration? periodicInterval,
    EditorLineHeight? lineHeight,
    bool? wordWrap,
    bool? focusMode,
    List<String>? hiddenTools,
  }) {
    return EditorPreferences(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      toolbarItems: toolbarItems ?? this.toolbarItems,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      periodicInterval: periodicInterval ?? this.periodicInterval,
      lineHeight: lineHeight ?? this.lineHeight,
      wordWrap: wordWrap ?? this.wordWrap,
      focusMode: focusMode ?? this.focusMode,
      hiddenTools: hiddenTools ?? this.hiddenTools,
    );
  }
}
