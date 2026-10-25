import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_app_bar.dart';
import 'package:devnotes/features/editor/presentation/widgets/markdown_preview.dart';
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

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
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

  /// Lỗi khi mở note — editor chỉ đọc và cho thoát, không nhốt user lại.
  Object? _loadError;

  /// Đang hỏi user về thay đổi từ bên ngoài — không hỏi chồng thêm lần nữa.
  bool _askingExternalChange = false;

  late final StateController<int> _openEditors;
  final _toolbarKey = GlobalKey();
  final _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    WidgetsBinding.instance.addObserver(this);
    _openEditors = ref.read(openEditorCountProvider.notifier);
    Future.microtask(() => _openEditors.state++);
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
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// App xuống nền (chuyển app, tắt màn hình) có thể bị hệ điều hành giết
  /// bất cứ lúc nào — lưu ngay thay vì chờ hết debounce.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        ref.read(saveStatusProvider) == SaveStatus.unsaved) {
      _save();
    }
  }

  /// Rời editor (nút Back trên app bar hoặc Back hệ thống): lưu trước. Lưu lỗi
  /// hoặc đang chờ user quyết về thay đổi bên ngoài thì ở lại.
  Future<void> _leave() async {
    final status = ref.read(saveStatusProvider);
    if (_loadedNote != null && status != SaveStatus.saved && !await _save()) {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _onControllerChanged() {
    final text = _textController.text;
    if (text == _lastText) return;
    _lastText = text;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
    _debounce?.cancel();
    final interval =
        ref.read(editorPreferencesProvider).valueOrNull?.autoSaveInterval ??
        EditorPreferences.defaultAutoSaveInterval;
    _debounce = Timer(interval, () => _save());
  }

  /// Ghi nội dung xuống file. Trả về `false` nếu không ghi — ghi lỗi (B-13:
  /// báo user, không nuốt lỗi) hoặc file đã bị đổi từ bên ngoài.
  ///
  /// [_loadedNote] là bản trên đĩa lần cuối editor đọc/ghi. Trước khi ghi,
  /// so với file hiện tại: khác nhau nghĩa là sync hay app khác vừa sửa file
  /// → không ghi đè, hỏi user. Xem DECISIONS.md, "Editor không ghi đè thay
  /// đổi từ bên ngoài" (2026-10-25).
  Future<bool> _save() async {
    if (!mounted || _loadedNote == null || _deleted) return false;
    if (_askingExternalChange) return false;
    _debounce?.cancel();
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
    final NoteFile updated;
    try {
      final repo = await ref.read(noteFileRepositoryProvider.future);
      // Note có thể vừa bị xóa trong lúc chờ ở trên (B-06).
      if (_deleted) return false;

      NoteFile? onDisk;
      try {
        onDisk = await repo.readNote(widget.filePath);
      } on FileSystemException {
        onDisk = null; // File bị xóa từ bên ngoài — ghi lại là khôi phục.
      }
      if (onDisk != null && _changedOutside(onDisk)) {
        if (mounted) {
          ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
          _askAboutExternalChange(onDisk);
        }
        return false;
      }

      updated = _loadedNote!.copyWith(content: _textController.text);
      final write = repo.saveNote(updated);
      _inFlightSave = write;
      await write;
    } catch (e) {
      if (mounted) {
        ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không lưu được ghi chú: $e')));
      }
      return false;
    }
    _loadedNote = updated;
    if (!mounted) return true;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    ref.invalidate(currentNoteProvider(widget.filePath));
    ref.invalidate(noteListProvider);
    return true;
  }

  bool _changedOutside(NoteFile onDisk) {
    final mine = _loadedNote!;
    return onDisk.content != mine.content ||
        onDisk.title != mine.title ||
        !listEquals(onDisk.tags, mine.tags);
  }

  Future<void> _askAboutExternalChange(NoteFile onDisk) async {
    _askingExternalChange = true;
    final keepMine = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ghi chú đã thay đổi bên ngoài'),
        content: const Text(
          'Trong lúc bạn đang sửa, ghi chú này vừa được thay đổi ở nơi khác '
          '(ví dụ do đồng bộ). Để không ghi đè mất bản đó, hãy chọn:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tải bản mới'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lưu bản của tôi thành note mới'),
          ),
        ],
      ),
    );
    _askingExternalChange = false;
    if (!mounted) return;

    final mine = _textController.text;
    if (keepMine == true) {
      try {
        final repo = await ref.read(noteFileRepositoryProvider.future);
        final copy = await repo.createNote(
          title: '${_loadedNote!.title} (bản sửa)',
          tags: _loadedNote!.tags,
        );
        await repo.saveNote(copy.copyWith(content: mine));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lưu bản của bạn thành "${copy.title}".'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không lưu được bản sao: $e')));
        }
        return; // Giữ nguyên nội dung đang sửa để user thử lại.
      }
    }
    // Cả hai lựa chọn đều kết thúc bằng việc hiện bản mới trên đĩa.
    _loadedNote = onDisk;
    _lastText = onDisk.content;
    _textController.text = onDisk.content;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    ref.invalidate(currentNoteProvider(widget.filePath));
    ref.invalidate(noteListProvider);
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
    try {
      await Share.shareXFiles([
        XFile(widget.filePath, mimeType: 'text/markdown'),
      ], subject: title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không chia sẻ được: $e')),
        );
      }
    }
  }

  void _showInfo() {
    final note = _loadedNote;
    if (note == null) return;
    final text = _textController.text;
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không xóa được ghi chú: $e')));
      }
      return;
    }
    ref.invalidate(noteListProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Future.microtask(() => _openEditors.state--);
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

    // Back hệ thống (nút/cử chỉ) cũng phải lưu trước khi rời — trước đây chỉ
    // nút Back trên app bar làm việc này, Back hệ thống làm mất chữ vừa gõ.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: colors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              EditorAppBar(
                title: noteAsync.valueOrNull?.title,
                saveStatus: saveStatus,
                currentPage: _currentPage,
                onBack: _leave,
                onMore: _showMoreMenu,
              ),
              Expanded(
                child: PageView(
                  key: _previewKey,
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    // Edit mode
                    if (_loadError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Không mở được ghi chú: $_loadError',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _textController,
                          // Chưa tải xong thì chưa cho gõ: chữ gõ lúc này sẽ bị
                          // nội dung note ghi đè khi tải xong.
                          readOnly: _loadedNote == null,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontFamily:
                                editorPrefs?.fontFamily ?? 'JetBrainsMono',
                            fontSize:
                                editorPrefs?.fontSize ??
                                EditorPreferences.defaultFontSize,
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
                      data: (_) => MarkdownPreview(
                        data: _textController.text,
                        fontFamily:
                            editorPrefs?.fontFamily ?? 'JetBrainsMono',
                        fontSize: editorPrefs?.fontSize ??
                            EditorPreferences.defaultFontSize,
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
                  visibleItemIds:
                      editorPrefs?.toolbarItems ??
                      EditorPreferences.defaultToolbarItems,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
