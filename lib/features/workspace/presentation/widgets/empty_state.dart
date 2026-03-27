import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onCreateFirst;

  const EmptyState({super.key, required this.onCreateFirst});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 80, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first note to get started',
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onCreateFirst,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.textOnAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Create your first note'),
          ),
        ],
      ),
    );
  }
}
