import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/onboarding/domain/sample_note.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

class OnboardingFirstNoteScreen extends ConsumerStatefulWidget {
  const OnboardingFirstNoteScreen({super.key});

  @override
  ConsumerState<OnboardingFirstNoteScreen> createState() =>
      _OnboardingFirstNoteScreenState();
}

class _OnboardingFirstNoteScreenState
    extends ConsumerState<OnboardingFirstNoteScreen> {
  /// Đang tạo — chặn bấm lần hai (từng sinh thêm welcome-to-devnotes-1.md).
  bool _creating = false;

  Future<void> _createAndStart() async {
    if (_creating) return;
    setState(() => _creating = true);
    // Note mẫu viết bằng đúng ngôn ngữ giao diện đang dùng.
    final sample =
        SampleNote.forLanguage(Localizations.localeOf(context).languageCode);
    final l = context.l10n;
    try {
      final repo = await ref.read(noteFileRepositoryProvider.future);
      final note = await repo.createNote(
        title: sample.title,
        tags: SampleNote.tags,
      );
      await repo.saveNote(note.copyWith(content: sample.content));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.noteCreateFailed('$e'))));
      }
      return;
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;

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
                  l.firstNoteTitle,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.firstNoteBody,
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
                    onPressed: _creating ? null : _createAndStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l.firstNoteButton,
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
