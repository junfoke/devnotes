import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/editor/domain/editor_tool.dart';
import 'package:devnotes/features/editor/presentation/editor_display_actions.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_tools_sheet.dart';
import 'package:devnotes/features/editor/presentation/editor_tool_labels.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';

/// Lưu [prefs] rồi làm mới [editorPreferencesProvider] — editor đang mở áp
/// dụng ngay.
Future<void> _savePrefs(WidgetRef ref, EditorPreferences prefs) async {
  try {
    await ref.read(preferencesRepoProvider).saveEditorPreferences(prefs);
  } catch (e) {
    // Sheet vẫn hiện lựa chọn mới; báo để user biết nó chưa được lưu.
    final context = ref.context;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsSaveFailed('$e'))),
      );
    }
    return;
  }
  ref.invalidate(editorPreferencesProvider);
}

/// Bottom sheet chọn font và cỡ chữ cho editor.
class FontSettingsSheet extends ConsumerStatefulWidget {
  const FontSettingsSheet({super.key, required this.initial});

  final EditorPreferences initial;

  static const fontFamilies = ['JetBrainsMono', 'FiraCode'];
  static const minSize = EditorPreferences.minFontSize;
  static const maxSize = EditorPreferences.maxFontSize;

  @override
  ConsumerState<FontSettingsSheet> createState() => _FontSettingsSheetState();
}

class _FontSettingsSheetState extends ConsumerState<FontSettingsSheet> {
  late EditorPreferences _prefs = widget.initial;

  void _update(EditorPreferences prefs) {
    setState(() => _prefs = prefs);
    _savePrefs(ref, prefs);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final size = _prefs.fontSize.clamp(
      FontSettingsSheet.minSize,
      FontSettingsSheet.maxSize,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsFontAndSize,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _prefs.fontFamily,
              onChanged: (v) => _update(_prefs.copyWith(fontFamily: v)),
              child: Column(
                children: [
                  for (final family in FontSettingsSheet.fontFamilies)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: family,
                      title: Text(
                        family,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontFamily: family,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(l.fontSize, style: TextStyle(color: colors.textSecondary)),
                Expanded(
                  child: Slider(
                    value: size,
                    min: FontSettingsSheet.minSize,
                    max: FontSettingsSheet.maxSize,
                    divisions: 12,
                    label: size.round().toString(),
                    onChanged: (v) =>
                        setState(() => _prefs = _prefs.copyWith(fontSize: v)),
                    onChangeEnd: (v) => _update(_prefs.copyWith(fontSize: v)),
                  ),
                ),
                Text(
                  '${size.round()}',
                  style: TextStyle(color: colors.textPrimary),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.codeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l.fontPreviewSample,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: _prefs.fontFamily,
                  fontSize: size,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet cấu hình thanh công cụ và bảng Công cụ soạn thảo: liệt kê mọi
/// công cụ, mục ghim nằm trên cùng (kéo để đổi thứ tự), mỗi mục có công tắc
/// "Ghim" và "Hiện trong bảng".
///
/// Dùng chung [EditorPreferences] và [EditorDisplayActions] với bảng ⋯ của
/// editor nên đổi ở đâu cũng phản ánh ở chỗ kia. Mục ẩn khỏi bảng vẫn được
/// liệt kê ở đây để bật lại.
class ToolbarLayoutSheet extends ConsumerWidget {
  const ToolbarLayoutSheet({super.key, required this.initial});

  /// Cài đặt lúc mở sheet; chỉ dùng khi provider chưa tải xong.
  final EditorPreferences initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final prefs = ref.watch(editorPreferencesProvider).valueOrNull ?? initial;
    final actions = EditorDisplayActions(context);
    final pinnedIds = prefs.toolbarItems.toSet();
    final hidden = prefs.hiddenTools.toSet();
    final byId = {for (final t in EditorTool.all) t.id: t};
    // Id lạ (không còn trong EditorTool.all) bị bỏ qua.
    final pinned = [
      for (final id in prefs.toolbarItems)
        if (byId.containsKey(id)) byId[id]!,
    ];
    final small = TextStyle(color: colors.textMuted, fontSize: 12);

    Widget row(EditorTool t, {Widget? leading}) => Row(
      key: ValueKey('layout-row-${t.id}'),
      children: [
        SizedBox(width: 40, child: leading ?? const SizedBox.shrink()),
        SizedBox(
          width: 32,
          child: EditorToolGlyph(tool: t, color: colors.textSecondary),
        ),
        Expanded(
          child: Text(
            editorToolLabel(l, t.id),
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        SizedBox(
          width: 72,
          child: Switch(
            key: Key('pin-${t.id}'),
            value: pinnedIds.contains(t.id),
            onChanged: (v) => actions.setPinned(t.id, v),
          ),
        ),
        SizedBox(
          width: 72,
          child: Switch(
            key: Key('show-${t.id}'),
            value: !hidden.contains(t.id),
            onChanged: (v) => actions.setShownInSheet(t.id, v),
          ),
        ),
      ],
    );

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                l.settingsToolbarLayout,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(l.toolbarLayoutHint, style: small),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      for (final text in [
                        l.editorToolsPin,
                        l.editorToolsShowInSheet,
                      ])
                        SizedBox(
                          width: 72,
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: small,
                          ),
                        ),
                    ],
                  ),
                  if (pinned.isNotEmpty) ...[
                    sectionTitle(l.toolbarLayoutPinnedTitle),
                    ReorderableListView(
                      key: const Key('pinned-list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        final ids = [for (final t in pinned) t.id];
                        ids.insert(newIndex, ids.removeAt(oldIndex));
                        actions.setPinnedOrder(ids);
                      },
                      children: [
                        for (var i = 0; i < pinned.length; i++)
                          KeyedSubtree(
                            key: ValueKey('pinned-${pinned[i].id}'),
                            child: row(
                              pinned[i],
                              leading: ReorderableDragStartListener(
                                key: Key('drag-${pinned[i].id}'),
                                index: i,
                                child: Icon(
                                  Icons.drag_handle,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  for (final group in editorToolGroupOrder)
                    ...() {
                      final tools = [
                        for (final t in EditorTool.all)
                          if (t.group == group && !pinnedIds.contains(t.id)) t,
                      ];
                      if (tools.isEmpty) return const <Widget>[];
                      return [
                        sectionTitle(
                          '${l.toolbarLayoutOthersTitle} · '
                          '${editorToolGroupTitle(l, group)}',
                        ),
                        for (final t in tools) row(t),
                      ];
                    }(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet chọn chế độ sync tự động. Xem DECISIONS.md, "Sync tự động".
class SyncFrequencySheet extends ConsumerStatefulWidget {
  const SyncFrequencySheet({super.key, required this.initial});

  final EditorPreferences initial;

  static const intervals = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  @override
  ConsumerState<SyncFrequencySheet> createState() => _SyncFrequencySheetState();
}

class _SyncFrequencySheetState extends ConsumerState<SyncFrequencySheet> {
  late EditorPreferences _prefs = widget.initial;

  void _update(EditorPreferences prefs) {
    setState(() => _prefs = prefs);
    _savePrefs(ref, prefs);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    TextStyle titleStyle() => TextStyle(color: colors.textPrimary);
    TextStyle subStyle() => TextStyle(color: colors.textMuted, fontSize: 12);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsSyncFrequency,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<SyncFrequency>(
              groupValue: _prefs.syncFrequency,
              onChanged: (v) {
                if (v != null) _update(_prefs.copyWith(syncFrequency: v));
              },
              child: Column(
                children: [
                  RadioListTile<SyncFrequency>(
                    contentPadding: EdgeInsets.zero,
                    value: SyncFrequency.manual,
                    title: Text(l.syncFrequencyManual, style: titleStyle()),
                    subtitle: Text(
                      l.syncFrequencyManualDesc,
                      style: subStyle(),
                    ),
                  ),
                  RadioListTile<SyncFrequency>(
                    contentPadding: EdgeInsets.zero,
                    value: SyncFrequency.onOpen,
                    title: Text(l.syncFrequencyOnOpen, style: titleStyle()),
                    subtitle: Text(
                      l.syncFrequencyOnOpenDesc,
                      style: subStyle(),
                    ),
                  ),
                  RadioListTile<SyncFrequency>(
                    contentPadding: EdgeInsets.zero,
                    value: SyncFrequency.periodic,
                    title: Text(l.syncFrequencyPeriodic, style: titleStyle()),
                    subtitle: Text(
                      l.syncFrequencyPeriodicDesc,
                      style: subStyle(),
                    ),
                  ),
                ],
              ),
            ),
            if (_prefs.syncFrequency == SyncFrequency.periodic)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final d in SyncFrequencySheet.intervals)
                      ChoiceChip(
                        label: Text(l.syncFrequencyMinutes(d.inMinutes)),
                        selected: _prefs.periodicInterval == d,
                        onSelected: (_) =>
                            _update(_prefs.copyWith(periodicInterval: d)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(l.syncFrequencyFootnote, style: subStyle()),
          ],
        ),
      ),
    );
  }
}
