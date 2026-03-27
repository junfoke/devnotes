import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_app_bar.dart';
import 'package:devnotes/features/editor/presentation/widgets/markdown_toolbar.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String filePath;
  const EditorScreen({super.key, required this.filePath});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _pageController = PageController();
  final _textController = TextEditingController();
  Timer? _debounce;
  int _currentPage = 0;
  NoteFile? _loadedNote;

  @override
  void initState() {
    super.initState();
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      final note = await ref.read(currentNoteProvider(widget.filePath).future);
      if (!mounted) return;
      _loadedNote = note;
      _textController.text = note.content;
    } catch (e) {
      // Error is surfaced via noteAsync.when() in the preview pane
    }
  }

  void _onTextChanged(String value) {
    ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => _save());
  }

  Future<void> _save() async {
    if (!mounted || _loadedNote == null) return;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
    final updated = _loadedNote!.copyWith(content: _textController.text);
    final repo = await ref.read(noteFileRepositoryProvider.future);
    await repo.saveNote(updated);
    if (!mounted) return;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    ref.invalidate(currentNoteProvider(widget.filePath));
    ref.invalidate(noteListProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final saveStatus = ref.watch(saveStatusProvider);
    final noteAsync = ref.watch(currentNoteProvider(widget.filePath));

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            EditorAppBar(
              saveStatus: saveStatus,
              currentPage: _currentPage,
              onBack: () async {
                if (saveStatus != SaveStatus.saved) await _save();
                if (context.mounted) context.pop();
              },
              onMore: () {
                // TODO: Task 14 — more menu
              },
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Edit mode
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _textController,
                      onChanged: _onTextChanged,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 14,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Start writing...',
                      ),
                    ),
                  ),
                  // Preview mode
                  noteAsync.when(
                    data: (_) => Markdown(
                      data: _textController.text,
                      padding: const EdgeInsets.all(20),
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            height: 1.6),
                        h1: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                        h2: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        h3: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        code: TextStyle(
                          color: colors.accentLight,
                          backgroundColor: colors.codeBg,
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: colors.codeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
            if (_currentPage == 0)
              MarkdownToolbar(
                textController: _textController,
                visibleItemIds: EditorPreferences.defaultToolbarItems,
              ),
          ],
        ),
      ),
    );
  }
}
