import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/domain/editor_tool.dart';
import 'package:devnotes/features/editor/presentation/editor_display_actions.dart';
import 'package:devnotes/features/editor/presentation/editor_tool_labels.dart';
import 'package:devnotes/features/editor/presentation/editor_tool_runner.dart';
import 'package:devnotes/features/editor/presentation/widgets/tool_pickers.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';

/// Thứ tự các nhóm trong bảng: Hiển thị ở đầu, "Định dạng" (nút Markdown)
/// ở cuối.
const _groupOrder = [
  EditorToolGroup.display,
  EditorToolGroup.edit,
  EditorToolGroup.insert,
  EditorToolGroup.view,
  EditorToolGroup.format,
];

String _groupTitle(AppLocalizations l, EditorToolGroup group) =>
    switch (group) {
      EditorToolGroup.display => l.editorToolGroupDisplay,
      EditorToolGroup.edit => l.editorToolGroupEdit,
      EditorToolGroup.insert => l.editorToolGroupInsert,
      EditorToolGroup.view => l.editorToolGroupView,
      EditorToolGroup.format => l.editorToolGroupFormat,
    };

/// Mở bảng "Công cụ soạn thảo" (nút `⋯` trên thanh công cụ).
///
/// Bàn phím được ẩn khi mở. Mục trong `hiddenTools` không hiện; mục đang
/// ghim vẫn hiện (bảng là nơi đầy đủ). Nhóm Hiển thị đổi cài đặt ngay và
/// giữ bảng mở; các nhóm khác đóng bảng rồi chạy công cụ qua [runner].
Future<void> showEditorToolsSheet(
  BuildContext context, {
  required EditorToolRunner runner,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => EditorToolsSheet(runner: runner),
  );
}

class EditorToolsSheet extends ConsumerStatefulWidget {
  const EditorToolsSheet({super.key, required this.runner});

  final EditorToolRunner runner;

  @override
  ConsumerState<EditorToolsSheet> createState() => _EditorToolsSheetState();
}

class _EditorToolsSheetState extends ConsumerState<EditorToolsSheet> {
  /// Chế độ "Tùy chỉnh": mỗi mục có công tắc Ghim và Hiện trong bảng.
  bool _customizing = false;

  EditorDisplayActions get _display => EditorDisplayActions(context);

  void _runTool(String id) {
    Navigator.pop(context);
    widget.runner.run(id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final prefs =
        ref.watch(editorPreferencesProvider).valueOrNull ??
        const EditorPreferences();

    return SafeArea(
      child: ConstrainedBox(
        key: const Key('editor-tools-sheet'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.editorToolsButton,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('tools-customize'),
                    onPressed: () =>
                        setState(() => _customizing = !_customizing),
                    child: Text(
                      _customizing ? l.editorToolsDone : l.editorToolsCustomize,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                // Đổi chế độ thì danh sách mới bắt đầu lại từ đầu.
                key: ValueKey(_customizing),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: _customizing
                    ? _customizeChildren(prefs)
                    : _toolChildren(prefs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(EditorToolGroup group) {
    final colors = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        _groupTitle(context.l10n, group),
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _toolChildren(EditorPreferences prefs) {
    final hidden = prefs.hiddenTools.toSet();
    final l = context.l10n;
    return [
      for (final group in _groupOrder)
        ...() {
          final tools = [
            for (final t in EditorTool.all)
              if (t.group == group && !hidden.contains(t.id)) t,
          ];
          if (tools.isEmpty) return const <Widget>[];
          return [
            _groupHeader(group),
            if (group == EditorToolGroup.display)
              ..._displayControls(prefs, {for (final t in tools) t.id})
            else
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final t in tools)
                    if (t.id != 'symbols')
                      _SheetToolButton(
                        tool: t,
                        label: editorToolLabel(l, t.id),
                        onTap: () => _runTool(t.id),
                      ),
                ],
              ),
            if (tools.any((t) => t.id == 'symbols')) ...[
              const SizedBox(height: 8),
              Text(
                editorToolLabel(l, 'symbols'),
                style: TextStyle(
                  color: Theme.of(context).appColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              SymbolRow(onInsert: widget.runner.insertSymbol),
            ],
          ];
        }(),
    ];
  }

  /// Nhóm Hiển thị: điều khiển trực tiếp, bấm không đóng bảng. Chỉ dựng các
  /// điều khiển có id trong [shown].
  List<Widget> _displayControls(EditorPreferences prefs, Set<String> shown) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final label = TextStyle(color: colors.textSecondary, fontSize: 13);
    final size = prefs.fontSize.round();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return [
      if (shown.contains('font')) ...[
        Text(editorToolLabel(l, 'font'), style: label),
        Wrap(
          spacing: 8,
          children: [
            for (final family in EditorDisplayActions.fontCycle)
              ChoiceChip(
                label: Text(
                  switch (family) {
                    'JetBrainsMono' => 'JetBrains Mono',
                    'FiraCode' => 'Fira Code',
                    _ => l.editorFontSystem,
                  },
                  style: TextStyle(
                    fontFamily: family == EditorPreferences.systemFont
                        ? null
                        : family,
                  ),
                ),
                selected: prefs.fontFamily == family,
                onSelected: (_) => _display.setFontFamily(family),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
      if (shown.contains('size_down') || shown.contains('size_up'))
        Row(
          children: [
            Expanded(child: Text(l.fontSize, style: label)),
            if (shown.contains('size_down'))
              IconButton(
                tooltip: editorToolLabel(l, 'size_down'),
                onPressed: size > EditorPreferences.minFontSize
                    ? () => _display.changeFontSize(-1)
                    : null,
                icon: const Text('A−', style: TextStyle(fontSize: 14)),
              ),
            SizedBox(
              width: 32,
              child: Text(
                '$size',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textPrimary),
              ),
            ),
            if (shown.contains('size_up'))
              IconButton(
                tooltip: editorToolLabel(l, 'size_up'),
                onPressed: size < EditorPreferences.maxFontSize
                    ? () => _display.changeFontSize(1)
                    : null,
                icon: const Text('A+', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      if (shown.contains('line_height')) ...[
        Text(editorToolLabel(l, 'line_height'), style: label),
        Wrap(
          spacing: 8,
          children: [
            for (final value in EditorLineHeight.values)
              ChoiceChip(
                label: Text(switch (value) {
                  EditorLineHeight.compact => l.lineHeightCompact,
                  EditorLineHeight.normal => l.lineHeightNormal,
                  EditorLineHeight.relaxed => l.lineHeightRelaxed,
                }),
                selected: prefs.lineHeight == value,
                onSelected: (_) => _display.setLineHeight(value),
              ),
          ],
        ),
      ],
      if (shown.contains('word_wrap'))
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.wrap_text),
          title: Text(editorToolLabel(l, 'word_wrap')),
          value: prefs.wordWrap,
          onChanged: _display.setWordWrap,
        ),
      if (shown.contains('focus_mode'))
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.center_focus_strong_outlined),
          title: Text(editorToolLabel(l, 'focus_mode')),
          value: prefs.focusMode,
          onChanged: _display.setFocusMode,
        ),
      if (shown.contains('theme'))
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Tooltip(
            message: editorToolLabel(l, 'theme'),
            child: OutlinedButton.icon(
              onPressed: _display.toggleTheme,
              icon: Icon(dark ? Icons.dark_mode : Icons.light_mode),
              label: Text(dark ? l.themeDark : l.themeLight),
            ),
          ),
        ),
    ];
  }

  List<Widget> _customizeChildren(EditorPreferences prefs) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final pinned = prefs.toolbarItems.toSet();
    final hidden = prefs.hiddenTools.toSet();
    final small = TextStyle(color: colors.textMuted, fontSize: 12);

    return [
      Text(l.editorToolsCustomizeHint, style: small),
      const SizedBox(height: 8),
      Row(
        children: [
          const Spacer(),
          for (final text in [l.editorToolsPin, l.editorToolsShowInSheet])
            SizedBox(
              width: 72,
              child: Text(text, textAlign: TextAlign.center, style: small),
            ),
        ],
      ),
      for (final group in _groupOrder) ...[
        _groupHeader(group),
        for (final t in EditorTool.all)
          if (t.group == group)
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: _ToolGlyph(tool: t, color: colors.textSecondary),
                ),
                Expanded(
                  child: Text(
                    editorToolLabel(l, t.id),
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Switch(
                    key: Key('pin-${t.id}'),
                    value: pinned.contains(t.id),
                    onChanged: (v) => _display.setPinned(t.id, v),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Switch(
                    key: Key('show-${t.id}'),
                    value: !hidden.contains(t.id),
                    onChanged: (v) => _display.setShownInSheet(t.id, v),
                  ),
                ),
              ],
            ),
      ],
    ];
  }
}

/// Icon (hoặc chữ như `H1`) của một công cụ.
class _ToolGlyph extends StatelessWidget {
  const _ToolGlyph({required this.tool, required this.color});

  final EditorTool tool;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = tool.glyph;
    if (glyph == null) return Icon(tool.icon, size: 20, color: color);
    return Text(
      glyph,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: tool.id.startsWith('h') ? null : 'JetBrainsMono',
      ),
    );
  }
}

/// Ô công cụ dạng lưới: icon và tên bên dưới.
class _SheetToolButton extends StatelessWidget {
  const _SheetToolButton({
    required this.tool,
    required this.label,
    required this.onTap,
  });

  final EditorTool tool;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 76,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ToolGlyph(tool: tool, color: colors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
