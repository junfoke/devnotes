import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
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

  /// Nội dung lần cuối listener thấy — để phân biệt sửa chữ với chỉ dời con trỏ.
  String _lastText = '';

  /// Note đã bị xóa từ menu ⋮ — mọi lần lưu sau đó phải bị bỏ qua.
  bool _deleted = false;
  Future<void>? _inFlightSave;
  final _toolbarKey = GlobalKey();
  final _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    // Nghe thẳng controller thay vì TextField.onChanged: onChanged bỏ sót mọi
    // thay đổi do code gán (toolbar Markdown) → mất dữ liệu (B-01).
    _textController.addListener(_onControllerChanged);
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
      // Gán _lastText trước để việc nạp nội dung không bị tính là một lần sửa.
      _lastText = note.content;
      _textController.text = note.content;
    } catch (e) {
      // Error is surfaced via noteAsync.when() in the preview pane
    }
  }

  void _onControllerChanged() {
    final text = _textController.text;
    if (text == _lastText) return;
    _lastText = text;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => _save());
  }

  /// Ghi nội dung xuống file. Trả về `false` nếu ghi lỗi — khi đó trạng thái
  /// về `unsaved` và người dùng được báo, không nuốt lỗi im lặng (B-13).
  Future<bool> _save() async {
    if (!mounted || _loadedNote == null || _deleted) return false;
    _debounce?.cancel();
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
    try {
      final updated = _loadedNote!.copyWith(content: _textController.text);
      final repo = await ref.read(noteFileRepositoryProvider.future);
      final write = repo.saveNote(updated);
      _inFlightSave = write;
      await write;
    } catch (e) {
      if (mounted) {
        ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được ghi chú: $e')),
        );
      }
      return false;
    }
    if (!mounted) return true;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    ref.invalidate(currentNoteProvider(widget.filePath));
    ref.invalidate(noteListProvider);
    return true;
  }

  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ'),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Thông tin'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteNote();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Chia sẻ file `.md` — lưu trước để file gửi đi là bản mới nhất.
  Future<void> _shareNote() async {
    if (ref.read(saveStatusProvider) != SaveStatus.saved && !await _save()) {
      return;
    }
    final title = _loadedNote?.title ?? p.basename(widget.filePath);
    await Share.shareXFiles(
      [XFile(widget.filePath, mimeType: 'text/markdown')],
      subject: title,
    );
  }

  void _showInfo() {
    final note = _loadedNote;
    if (note == null) return;
    final text = _textController.text;
    final words =
        text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    String fmt(DateTime t) {
      final l = t.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(note.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${p.basename(note.filePath)}'),
            Text('Tags: ${note.tags.isEmpty ? '—' : note.tags.join(', ')}'),
            Text('Tạo lúc: ${fmt(note.createdAt)}'),
            Text('Sửa lúc: ${fmt(note.updatedAt)}'),
            Text('$words từ · ${text.length} ký tự'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Xóa note đang mở. Phải chặn autosave trước: timer debounce đang chờ mà
  /// chạy sau khi xóa sẽ ghi lại file, khiến note "sống lại".
  Future<void> _deleteNote() async {
    final title = _loadedNote?.title ?? p.basename(widget.filePath);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: Text('Xóa "$title"? Không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _deleted = true;
    _debounce?.cancel();
    try {
      // Một lần ghi đang dở phải xong trước, nếu không nó ghi đè sau khi xóa.
      await _inFlightSave;
    } catch (_) {
      // Lần ghi đó lỗi thì cũng không còn gì để giữ — vẫn xóa tiếp.
    }
    try {
      final repo = await ref.read(noteFileRepositoryProvider.future);
      await repo.deleteNote(widget.filePath);
    } catch (e) {
      _deleted = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không xóa được ghi chú: $e')),
        );
      }
      return;
    }
    ref.invalidate(noteListProvider);
    if (mounted) Navigator.of(context).pop();
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
              title: noteAsync.valueOrNull?.title,
              saveStatus: saveStatus,
              currentPage: _currentPage,
              onBack: () async {
                // Lưu lỗi thì ở lại màn hình: thoát lúc này là bỏ mất nội dung.
                if (saveStatus != SaveStatus.saved && !await _save()) return;
                if (context.mounted) context.pop();
              },
              onMore: _showMoreMenu,
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
