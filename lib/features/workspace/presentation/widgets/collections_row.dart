import 'package:flutter/material.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class CollectionsRow extends StatelessWidget {
  final List<Collection> collections;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAdd;

  /// Nhấn giữ một chip collection (không áp dụng cho "All Notes").
  final ValueChanged<Collection>? onLongPress;

  const CollectionsRow({
    super.key,
    required this.collections,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip(context, 'All Notes', selectedId == null, () => onSelect(null)),
          ...collections.map((col) => _chip(
                context,
                col.name,
                selectedId == col.id,
                () => onSelect(col.id),
                onLongPress:
                    onLongPress == null ? null : () => onLongPress!(col),
              )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 18, color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap,
      {VoidCallback? onLongPress}) {
    final colors = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.accent : colors.bgSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.textOnAccent : colors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
