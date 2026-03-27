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
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/onboarding/application/tooltip_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
  final _toolbarKey = GlobalKey();
  final _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    _loadNote();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TooltipService.showTooltips(
        context: context,
        tooltipKey: 'editor',
        targets: [
          TooltipService.createTarget(
            key: _toolbarKey,
            title: 'Markdown Toolbar',
            description:
                'Quick-insert Markdown syntax — headings, bold, code blocks, and more.',
            align: ContentAlign.top,
          ),
          TooltipService.createTarget(
            key: _previewKey,
            title: 'Swipe to Preview',
            description:
                'Swipe left to see a rendered preview of your Markdown.',
          ),
        ],
      );
    });
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
    final prefsAsync = ref.watch(editorPreferencesProvider);
    final editorPrefs = prefsAsync.valueOrNull;
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
                // TODO: editor more menu (share, info, delete)
              },
            ),
            Expanded(
              child: PageView(
                key: _previewKey,
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
                        fontFamily: editorPrefs?.fontFamily ?? 'JetBrainsMono',
                        fontSize: editorPrefs?.fontSize ?? 14,
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
                key: _toolbarKey,
                textController: _textController,
                visibleItemIds: editorPrefs?.toolbarItems ?? EditorPreferences.defaultToolbarItems,
              ),
          ],
        ),
      ),
    );
  }
}
