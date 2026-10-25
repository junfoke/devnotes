import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/editor/domain/toolbar_item.dart';
import 'package:devnotes/features/editor/presentation/editor_tool_labels.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';

/// Lưu [prefs] và báo cho editor đọc lại ở lần mở note kế tiếp.
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
  static const minSize = 12.0;
  static const maxSize = 24.0;

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

/// Bottom sheet bật/tắt và sắp xếp các nút trên thanh công cụ Markdown.
class ToolbarLayoutSheet extends ConsumerStatefulWidget {
  const ToolbarLayoutSheet({super.key, required this.initial});

  final EditorPreferences initial;

  @override
  ConsumerState<ToolbarLayoutSheet> createState() => _ToolbarLayoutSheetState();
}

class _ToolbarLayoutSheetState extends ConsumerState<ToolbarLayoutSheet> {
  /// Thứ tự hiển thị: các nút đang bật trước (theo thứ tự đã lưu), rồi tới
  /// các nút đang tắt.
  late final List<ToolbarItem> _order;
  late final Set<String> _visible;

  @override
  void initState() {
    super.initState();
    final saved = widget.initial.toolbarItems;
    _visible = saved.toSet();
    _order = [
      for (final id in saved)
        ...ToolbarItem.allItems.where((item) => item.id == id),
      ...ToolbarItem.allItems.where((item) => !_visible.contains(item.id)),
    ];
  }

  void _persist() {
    final ids = [
      for (final item in _order)
        if (_visible.contains(item.id)) item.id,
    ];
    _savePrefs(ref, widget.initial.copyWith(toolbarItems: ids));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;

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
              child: Text(
                l.toolbarLayoutHint,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _order.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    _order.insert(newIndex, _order.removeAt(oldIndex));
                  });
                  _persist();
                },
                itemBuilder: (context, index) {
                  final item = _order[index];
                  return CheckboxListTile(
                    key: ValueKey(item.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _visible.contains(item.id),
                    onChanged: (checked) {
                      setState(() {
                        checked == true
                            ? _visible.add(item.id)
                            : _visible.remove(item.id);
                      });
                      _persist();
                    },
                    secondary: item.icon != null
                        ? Icon(item.icon, color: colors.textSecondary)
                        : Text(
                            item.label,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    title: Text(
                      editorToolLabel(l, item.id),
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  );
                },
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
