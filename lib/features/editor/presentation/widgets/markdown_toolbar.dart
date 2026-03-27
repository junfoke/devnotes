import 'dart:math';
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/domain/toolbar_item.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController textController;
  final List<String> visibleItemIds;

  const MarkdownToolbar({
    super.key,
    required this.textController,
    required this.visibleItemIds,
  });

  void _insertSyntax(ToolbarItem item) {
    final text = textController.text;
    final selection = textController.selection;

    // Normalise: no cursor → append at end; inverted range → swap
    final rawStart = selection.start;
    final start = rawStart < 0 ? text.length : min(selection.start, selection.end);
    final end = rawStart < 0 ? text.length : max(selection.start, selection.end);

    final selectedText = text.substring(start, end);

    // For block items, ensure we start on a new line
    var prefix = item.insertBefore;
    if (item.isBlock && start > 0 && text[start - 1] != '\n') {
      prefix = '\n$prefix';
    }

    final newText = text.replaceRange(
      start,
      end,
      '$prefix$selectedText${item.insertAfter}',
    );
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + prefix.length + selectedText.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final items = ToolbarItem.allItems
        .where((item) => visibleItemIds.contains(item.id))
        .toList();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _insertSyntax(item),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: item.icon != null
                    ? Icon(item.icon, size: 20, color: colors.textSecondary)
                    : Text(
                        item.label,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: item.id.startsWith('h')
                              ? 'Inter'
                              : 'JetBrainsMono',
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
