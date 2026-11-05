import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/domain/editor_tool.dart';
import 'package:devnotes/features/editor/presentation/editor_tool_labels.dart';

/// Thanh công cụ dưới editor: các mục đã ghim cuộn ngang, nút `⋯` mở bảng
/// "Công cụ soạn thảo" nằm cố định sát mép phải, luôn bấm được.
class EditorToolbar extends StatelessWidget {
  /// Id các mục ghim, theo thứ tự user đã sắp. Id không có trong
  /// [EditorTool.all] bị bỏ qua.
  final List<String> pinnedIds;

  /// `false` khi chưa tải xong / tải lỗi: các mục ghim bị vô hiệu, riêng
  /// nút `⋯` vẫn bấm được.
  final bool enabled;
  final void Function(String id) onTool;
  final VoidCallback onOpenSheet;

  const EditorToolbar({
    super.key,
    required this.pinnedIds,
    required this.enabled,
    required this.onTool,
    required this.onOpenSheet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final tools = [for (final id in pinnedIds) ?EditorTool.byId(id)];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _ToolButton(
                  tool: tool,
                  label: editorToolLabel(l, tool.id),
                  onTap: enabled ? () => onTool(tool.id) : null,
                );
              },
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.border)),
            ),
            child: IconButton(
              key: const Key('editor-tools-button'),
              tooltip: l.editorToolsButton,
              icon: Icon(Icons.more_horiz, color: colors.textSecondary),
              onPressed: onOpenSheet,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final EditorTool tool;
  final String label;
  final VoidCallback? onTap;

  const _ToolButton({required this.tool, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final color = onTap == null
        ? colors.textSecondary.withValues(alpha: 0.38)
        : colors.textSecondary;
    final glyph = tool.glyph;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: glyph == null
                ? Icon(tool.icon, size: 20, color: color)
                : Text(
                    glyph,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      // Nút H1-H3 dùng font mặc định của app.
                      fontFamily: tool.id.startsWith('h')
                          ? null
                          : 'JetBrainsMono',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
