import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/editor/domain/checklist_toggle.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_app_bar.dart';
import 'package:devnotes/features/editor/presentation/widgets/markdown_preview.dart';
import 'package:devnotes/features/editor/presentation/editor_tool_runner.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_toolbar.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_tools_sheet.dart';
import 'package:devnotes/features/editor/presentation/widgets/find_replace_bar.dart';
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
  final _undoController = UndoHistoryController();

  /// Đổi mỗi khi nạp nội dung từ đĩa (mở note, tải lại bản bên ngoài) để
  /// TextField dựng lại và lịch sử hoàn tác bắt đầu từ nội dung vừa nạp —
  /// hoàn tác không được đưa note về trống.
  ///
  /// Là GlobalKey để TextField giữ nguyên state (lịch sử hoàn tác, focus)
  /// khi cây bên trên đổi hình — bật/tắt tự xuống dòng bọc/bỏ vùng cuộn ngang.
  GlobalKey _fieldKey = GlobalKey();
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

  /// Tag mới user vừa sửa, chưa ghi xuống file.
  List<String>? _pendingTags;

  /// Đang hỏi user về thay đổi từ bên ngoài — không hỏi chồng thêm lần nữa.
  bool _askingExternalChange = false;

  /// Đang hiện thanh tìm & thay thế (công cụ `find_replace`).
  bool _showFind = false;

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
      final l = context.l10n;
      TooltipService.showTooltips(
        context: context,
        tooltipKey: 'editor',
        targets: [
          TooltipService.createTarget(
            key: _toolbarKey,
            title: l.tooltipToolbarTitle,
            description: l.tooltipToolbarDesc,
            align: ContentAlign.top,
          ),
          TooltipService.createTarget(
            key: _previewKey,
            title: l.tooltipPreviewTitle,
            description: l.tooltipPreviewDesc,
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
      _setLoadedText(note.content);
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// Nạp nội dung từ đĩa vào editor và bắt đầu lịch sử hoàn tác mới từ đó.
  /// Con trỏ đặt cuối văn bản: vùng chọn phải hợp lệ thì lịch sử mới ghi
  /// nhận giá trị đầu, và chèn từ toolbar khi chưa chạm vào văn bản vẫn
  /// rơi vào cuối như trước.
  void _setLoadedText(String content) {
    _textController.value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(offset: content.length),
    );
    _undoController.value = UndoHistoryValue.empty;
    _fieldKey = GlobalKey();
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

      updated = _loadedNote!.copyWith(
        content: _textController.text,
        tags: _pendingTags ?? _loadedNote!.tags,
      );
      final write = repo.saveNote(updated);
      _inFlightSave = write;
      await write;
    } catch (e) {
      if (mounted) {
        ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text(context.l10n.noteSaveFailed('$e'))));
      }
      return false;
    }
    _loadedNote = updated;
    _pendingTags = null;
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
    final l = context.l10n;
    final keepMine = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.externalChangeTitle),
        content: Text(l.externalChangeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.externalChangeReload),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.externalChangeKeepMine),
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
          title: l.editedCopyTitle(_loadedNote!.title),
          tags: _pendingTags ?? _loadedNote!.tags,
        );
        await repo.saveNote(copy.copyWith(content: mine));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.savedAsCopy(copy.title))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.copySaveFailed('$e'))));
        }
        return; // Giữ nguyên nội dung đang sửa để user thử lại.
      }
    }
    // Cả hai lựa chọn đều kết thúc bằng việc hiện bản mới trên đĩa.
    _loadedNote = onDisk;
    _pendingTags = null;
    _lastText = onDisk.content;
    setState(() => _setLoadedText(onDisk.content));
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    ref.invalidate(currentNoteProvider(widget.filePath));
    ref.invalidate(noteListProvider);
  }

  void _showMoreMenu() {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l.editorMenuShare),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(l.editorMenuEditTags),
              onTap: () {
                Navigator.pop(sheetContext);
                _editTags();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.editorMenuInfo),
              onTap: () {
                Navigator.pop(sheetContext);
                _showInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l.commonDelete,
                  style: const TextStyle(color: Colors.red)),
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

  /// Bấm ô checklist trong preview: đổi đúng dòng trong văn bản, autosave
  /// lo phần ghi như mọi lần sửa khác.
  void _toggleChecklist(int index, bool checked) {
    final updated = toggleChecklistItem(_textController.text, index, checked);
    if (updated == _textController.text) return;
    // Vùng chọn phải hợp lệ, nếu không lịch sử hoàn tác bỏ qua lần đổi này
    // và một lần hoàn tác sau đó lặng lẽ bỏ dấu ô vừa đánh.
    final offset = _textController.selection.baseOffset
        .clamp(0, updated.length)
        .toInt();
    setState(
      () => _textController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: offset),
      ),
    );
  }

  /// Đổi tag của note. Tag mới được ghi cùng nội dung đang gõ qua đúng đường
  /// lưu thường (_save), nên vẫn được kiểm tra thay đổi từ bên ngoài.
  Future<void> _editTags() async {
    final note = _loadedNote;
    if (note == null) return;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditTagsDialog(initial: _pendingTags ?? note.tags),
    );
    if (result == null || !mounted) return;

    final tags = <String>[];
    for (final raw in result.split(',')) {
      final tag = raw.trim();
      if (tag.isNotEmpty && !tags.contains(tag)) tags.add(tag);
    }
    if (listEquals(tags, note.tags) && _pendingTags == null) return;
    _pendingTags = tags;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
    await _save();
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
          SnackBar(content: Text(context.l10n.shareFailed('$e'))),
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
    final l = context.l10n;
    final dateFormat =
        DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
            .add_Hm();
    String fmt(DateTime t) => dateFormat.format(t.toLocal());

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(note.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.noteInfoFile(p.basename(note.filePath))),
            Text(l.noteInfoTags(
                note.tags.isEmpty ? '—' : note.tags.join(', '))),
            Text(l.noteInfoCreated(fmt(note.createdAt))),
            Text(l.noteInfoUpdated(fmt(note.updatedAt))),
            Text('${l.noteInfoWords(words)} · '
                '${l.noteInfoChars(text.length)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }

  /// Xóa note đang mở. Phải chặn autosave trước: timer debounce đang chờ mà
  /// chạy sau khi xóa sẽ ghi lại file, khiến note "sống lại".
  Future<void> _deleteNote() async {
    final title = _loadedNote?.title ?? p.basename(widget.filePath);
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteNoteTitle),
        content: Text(l.deleteNoteConfirm(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.commonDelete,
                style: const TextStyle(color: Colors.red)),
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
        ).showSnackBar(
            SnackBar(content: Text(l.noteDeleteFailed('$e'))));
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
    _undoController.dispose();
    super.dispose();
  }

  EditorToolRunner get _toolRunner => EditorToolRunner(
    text: _textController,
    undo: _undoController,
    context: context,
    ref: ref,
    onFindReplace: () {
      if (mounted) setState(() => _showFind = true);
    },
  );

  void _runTool(String id) => _toolRunner.run(id);

  /// Ô soạn. Tắt tự xuống dòng thì đặt trong vùng cuộn ngang, rộng ít nhất
  /// bằng màn hình và rộng theo dòng dài nhất — dòng dài không bị bẻ.
  Widget _buildTextField(EditorPreferences? editorPrefs) {
    final colors = Theme.of(context).appColors;
    final field = TextField(
      key: _fieldKey,
      controller: _textController,
      undoController: _undoController,
      // Chưa tải xong thì chưa cho gõ: chữ gõ lúc này sẽ bị
      // nội dung note ghi đè khi tải xong.
      readOnly: _loadedNote == null,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        color: colors.textPrimary,
        fontFamily: editorPrefs == null
            ? 'JetBrainsMono'
            : editorPrefs.fontFamilyOrNull,
        fontSize: editorPrefs?.fontSize ?? EditorPreferences.defaultFontSize,
        height: (editorPrefs?.lineHeight ?? EditorLineHeight.normal).value,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: context.l10n.editorHint,
      ),
    );
    if (editorPrefs?.wordWrap ?? true) return field;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: IntrinsicWidth(child: field),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
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
              // Chế độ tập trung ẩn thanh tiêu đề. Lối thoát: công tắc trong
              // bảng ⋯; Back hệ thống vẫn đi qua _leave (PopScope ở trên).
              if (!(editorPrefs?.focusMode ?? false))
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
                            l.noteOpenFailed('$_loadError'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      )
                    else
                      // Giữ trang soạn sống khi sang preview: TextField và
                      // lịch sử hoàn tác không bị dựng lại (ruling R6).
                      _KeepAlivePage(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildTextField(editorPrefs),
                        ),
                      ),
                    // Preview mode
                    noteAsync.when(
                      data: (_) => MarkdownPreview(
                        data: _textController.text,
                        onToggleChecklist: _loadedNote == null ? null : _toggleChecklist,
                        // Font hệ thống: khối code trong preview vẫn dùng
                        // font đơn cách mặc định.
                        fontFamily:
                            editorPrefs?.fontFamilyOrNull ?? 'JetBrainsMono',
                        fontSize: editorPrefs?.fontSize ??
                            EditorPreferences.defaultFontSize,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Center(child: Text(l.errorWithDetail('$e'))),
                    ),
                  ],
                ),
              ),
              if (_currentPage == 0 && _showFind)
                FindReplaceBar(
                  text: _textController,
                  onClose: () => setState(() => _showFind = false),
                ),
              if (_currentPage == 0)
                EditorToolbar(
                  key: _toolbarKey,
                  pinnedIds:
                      editorPrefs?.toolbarItems ??
                      EditorPreferences.defaultToolbarItems,
                  enabled: _loadedNote != null,
                  onTool: _runTool,
                  onOpenSheet: () =>
                      showEditorToolsSheet(context, runner: _toolRunner),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Giữ một trang của PageView sống khi nó trượt khỏi màn hình.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Dialog sửa tag. Tự giữ controller của mình — dispose ngay sau showDialog
/// làm hiệu ứng đóng dialog dùng controller đã hủy.
class _EditTagsDialog extends StatefulWidget {
  const _EditTagsDialog({required this.initial});

  final List<String> initial;

  @override
  State<_EditTagsDialog> createState() => _EditTagsDialogState();
}

class _EditTagsDialogState extends State<_EditTagsDialog> {
  late final _controller =
      TextEditingController(text: widget.initial.join(', '));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.editorMenuEditTags),
      content: TextField(
        key: const Key('edit-tags-field'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l.editTagsHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
