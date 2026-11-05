import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/features/git_sync/domain/conflict_parser.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/application/sync_controller.dart';
import 'package:devnotes/features/git_sync/presentation/git_messages.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';

class ConflictScreen extends ConsumerStatefulWidget {
  final String filePath;

  /// Tên phía "ours" (HEAD) và "theirs" để hiện trên nhãn và nút. Khi chuyển
  /// branch thì là tên hai branch (giữ nguyên, không dịch) — nếu không, bản
  /// ghi chú user đang dùng lại bị gọi là "REMOTE (theirs)" (B-19). Null (sau
  /// pull) thì hiện "máy này" / "remote" theo ngôn ngữ đang chọn.
  final String? oursName;
  final String? theirsName;

  const ConflictScreen({
    super.key,
    required this.filePath,
    this.oursName,
    this.theirsName,
  });

  /// Đường dẫn route tới màn conflict của [filePath], giữ nguyên tên hai phía.
  static String location(String filePath, {String? ours, String? theirs}) {
    final query = {
      if (ours != null) 'ours': ours,
      if (theirs != null) 'theirs': theirs,
    };
    final path = '/conflict/${Uri.encodeComponent(filePath)}';
    return query.isEmpty ? path : '$path?${Uri(queryParameters: query).query}';
  }

  @override
  ConsumerState<ConflictScreen> createState() => _ConflictScreenState();
}

class _ConflictScreenState extends ConsumerState<ConflictScreen> {
  late String _rawContent;
  late List<ConflictBlock> _blocks;
  bool _loading = true;

  /// Lỗi khi đọc file (file mất, không đọc được) — hiện thay vì quay mãi.
  Object? _loadError;

  /// Đang ghi/đánh dấu — khóa ba nút để không bấm chồng.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      _rawContent = await File(widget.filePath).readAsString();
      _blocks = ConflictParser.parse(_rawContent);
    } catch (e) {
      _loadError = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _hasMarkers => ConflictParser.hasConflicts(_rawContent);

  /// Ghi bản đã giải quyết, báo git là file này xong, rồi sang file conflict
  /// kế tiếp — hoặc quay về nếu đã hết. Commit để lần Sync sau lo.
  Future<void> _resolve(Resolution? resolution) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final List<String> remaining;
    try {
      remaining = await ref.read(syncControllerProvider).exclusive(() async {
        if (resolution != null) {
          final resolved = ConflictParser.resolveAll(_rawContent, resolution);
          await File(widget.filePath).writeAsString(resolved);
        }
        final client = await ref.read(gitClientProvider.future);
        await client.markResolved(widget.filePath);
        return client.conflictedFiles();
      });
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
          SnackBar(content: Text(l.conflictResolveFailed(describeError(l, e)))));
      return;
    }
    ref.invalidate(noteListProvider);
    if (!mounted) return;

    if (remaining.isNotEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.conflictRemaining(remaining.length))));
      context.pushReplacement(ConflictScreen.location(remaining.first,
          ours: widget.oursName, theirs: widget.theirsName));
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text(l.conflictAllResolved)));
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final oursName = widget.oursName ?? l.conflictThisDevice;
    final theirsName = widget.theirsName ?? l.conflictRemote;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        appBar: AppBar(backgroundColor: colors.bgPrimary),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || !_hasMarkers) {
      return _buildMessage(colors);
    }

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    Text(l.conflictTitle,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _blocks.length,
                itemBuilder: (context, index) {
                  final block = _blocks[index];
                  if (block.type == BlockType.clean) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        block.content,
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13),
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.error.withAlpha(100)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.success.withAlpha(30),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.conflictVersionOn(oursName.toUpperCase()),
                                  style: TextStyle(
                                      color: colors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(block.localContent!,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: colors.border),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.accentLight.withAlpha(30),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  l.conflictVersionOn(theirsName.toUpperCase()),
                                  style: TextStyle(
                                      color: colors.accentLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(block.remoteContent!,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _resolve(Resolution.keepMine),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.success,
                        side: BorderSide(color: colors.success),
                      ),
                      child: Text(l.conflictKeep(oursName),
                          textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _resolve(Resolution.keepTheirs),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accentLight,
                        side: BorderSide(color: colors.accentLight),
                      ),
                      child: Text(l.conflictKeep(theirsName),
                          textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _resolve(Resolution.keepBoth),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent),
                      child: Text(l.conflictKeepBoth,
                          style: TextStyle(color: colors.textOnAccent)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// File không đọc được, hoặc không còn dấu xung đột (đã sửa tay trong
  /// editor) — giải thích thay vì quay mãi hay hiện ba nút vô nghĩa.
  Widget _buildMessage(AppColorScheme colors) {
    final error = _loadError;
    final l = context.l10n;
    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        title: Text(l.conflictTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(error != null ? Icons.error_outline : Icons.check_circle,
                size: 48,
                color: error != null ? colors.error : colors.success),
            const SizedBox(height: 16),
            Text(
              error != null
                  ? l.conflictReadFailed('$error')
                  : l.conflictNoMarkers,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textPrimary),
            ),
            const SizedBox(height: 24),
            if (error == null)
              ElevatedButton(
                onPressed: _busy ? null : () => _resolve(null),
                child: Text(l.conflictMarkResolved),
              ),
          ],
        ),
      ),
    );
  }
}
