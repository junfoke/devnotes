import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

class OnboardingFirstNoteScreen extends ConsumerWidget {
  const OnboardingFirstNoteScreen({super.key});

  static const _sampleContent = '''# Welcome to DevNotes!

This is your first note. Here's a quick Markdown guide:

## Text Formatting
- **Bold** text with `**double asterisks**`
- _Italic_ text with `_underscores_`
- ~~Strikethrough~~ with `~~tildes~~`

## Code
Inline code with backticks: `print('Hello')`

Code blocks with triple backticks:
```dart
void main() {
  print('Hello, DevNotes!');
}
```

## Lists
- Unordered items with `-`
1. Ordered items with numbers

## Task Lists
- [x] Install DevNotes
- [ ] Write your first note
- [ ] Set up Git sync

Happy note-taking!
''';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, size: 60, color: colors.accent),
                const SizedBox(height: 24),
                Text(
                  'Your First Note',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'ll create a sample note with a Markdown guide to get you started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final repo = await ref
                          .read(noteFileRepositoryProvider.future);
                      final note = await repo.createNote(
                        title: 'Welcome to DevNotes',
                        tags: ['getting-started'],
                      );
                      final updated =
                          note.copyWith(content: _sampleContent);
                      await repo.saveNote(updated);

                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_complete', true);

                      if (context.mounted) context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create & Start',
                      style: TextStyle(
                        color: colors.textOnAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
