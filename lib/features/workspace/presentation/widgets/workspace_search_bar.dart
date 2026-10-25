import 'package:flutter/material.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class WorkspaceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  const WorkspaceSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      // Rebuilds on every keystroke so the clear button appears/disappears
      // with the field content.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: context.l10n.searchHint,
            hintStyle: TextStyle(color: colors.textMuted),
            prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, color: colors.textMuted, size: 20),
                    tooltip: context.l10n.searchClearTooltip,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            filled: true,
            fillColor: colors.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
