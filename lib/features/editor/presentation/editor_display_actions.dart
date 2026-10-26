import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';

/// Đổi cài đặt hiển thị của editor (font, cỡ chữ, giãn dòng, tự xuống dòng,
/// chế độ tập trung, sáng/tối) và cấu hình ghim/ẩn công cụ.
///
/// Dùng chung cho nhóm Hiển thị trong bảng "Công cụ soạn thảo" và cho các
/// nút hiển thị được ghim lên thanh công cụ (ruling R2) — một chỗ logic.
/// Cài đặt áp dụng cho mọi note (lưu trong [EditorPreferences]).
class EditorDisplayActions {
  /// Giữ container và messenger ngay lúc tạo: bảng có thể đã đóng (widget
  /// bị hủy) khi lần lưu xong, editor vẫn phải được báo đọc lại.
  EditorDisplayActions(BuildContext context)
    : _container = ProviderScope.containerOf(context, listen: false),
      _messenger = ScaffoldMessenger.maybeOf(context),
      _l10n = context.l10n,
      _dark = Theme.of(context).brightness == Brightness.dark;

  final ProviderContainer _container;
  final ScaffoldMessengerState? _messenger;
  final AppLocalizations _l10n;

  /// Màn hình đang tối (đã tính cả chế độ "theo hệ thống").
  final bool _dark;

  /// Thứ tự vòng của nút `font`.
  static const fontCycle = [
    'JetBrainsMono',
    'FiraCode',
    EditorPreferences.systemFont,
  ];

  /// Tên hiển thị của một font trong [fontCycle] (bảng công cụ và Settings).
  static String fontLabel(AppLocalizations l, String family) =>
      switch (family) {
        'JetBrainsMono' => 'JetBrains Mono',
        'FiraCode' => 'Fira Code',
        EditorPreferences.systemFont => l.editorFontSystem,
        _ => family,
      };

  /// Các lần đổi chạy nối tiếp: bấm A+ hai lần thật nhanh phải ra +2, không
  /// được để lần sau đọc bản cũ rồi ghi đè lần trước.
  /// Hàng đợi gắn với từng ProviderContainer (mỗi app/test một hàng).
  static final _queues = Expando<Future<void>>();

  /// Đọc cài đặt mới nhất, áp [change], lưu rồi báo editor đọc lại.
  Future<void> update(EditorPreferences Function(EditorPreferences) change) {
    final previous = _queues[_container] ?? Future<void>.value();
    final run = previous.then((_) => _apply(change));
    _queues[_container] = run.catchError((_) {});
    return run;
  }

  Future<void> _apply(
    EditorPreferences Function(EditorPreferences) change,
  ) async {
    final repo = _container.read(preferencesRepoProvider);
    try {
      final current = await repo.loadEditorPreferences();
      await repo.saveEditorPreferences(change(current));
    } catch (e) {
      _messenger?.showSnackBar(
        SnackBar(content: Text(_l10n.settingsSaveFailed('$e'))),
      );
      return;
    }
    _container.invalidate(editorPreferencesProvider);
  }

  Future<void> setFontFamily(String family) =>
      update((p) => p.copyWith(fontFamily: family));

  Future<void> cycleFont() => update((p) {
    final next = (fontCycle.indexOf(p.fontFamily) + 1) % fontCycle.length;
    return p.copyWith(fontFamily: fontCycle[next]);
  });

  /// Đổi cỡ chữ [delta] điểm, giữ trong 12–24.
  Future<void> changeFontSize(int delta) => update(
    (p) => p.copyWith(
      fontSize: (p.fontSize.roundToDouble() + delta).clamp(
        EditorPreferences.minFontSize,
        EditorPreferences.maxFontSize,
      ),
    ),
  );

  Future<void> setLineHeight(EditorLineHeight value) =>
      update((p) => p.copyWith(lineHeight: value));

  Future<void> cycleLineHeight() => update((p) {
    const all = EditorLineHeight.values;
    return p.copyWith(lineHeight: all[(p.lineHeight.index + 1) % all.length]);
  });

  Future<void> setWordWrap(bool value) =>
      update((p) => p.copyWith(wordWrap: value));

  Future<void> toggleWordWrap() =>
      update((p) => p.copyWith(wordWrap: !p.wordWrap));

  Future<void> setFocusMode(bool value) =>
      update((p) => p.copyWith(focusMode: value));

  Future<void> toggleFocusMode() =>
      update((p) => p.copyWith(focusMode: !p.focusMode));

  /// Sáng ↔ tối. Đang "theo hệ thống" thì chuyển sang ngược với độ sáng
  /// đang thấy trên màn hình.
  Future<void> toggleTheme() => _container
      .read(themeProvider.notifier)
      .setTheme(_dark ? ThemePreference.light : ThemePreference.dark);

  /// Ghim [id] lên cuối thanh công cụ, hoặc bỏ ghim.
  Future<void> setPinned(String id, bool pinned) => update((p) {
    final items = [...p.toolbarItems]..remove(id);
    if (pinned) items.add(id);
    return p.copyWith(toolbarItems: items);
  });

  /// Đặt lại thứ tự các nút đang ghim (dùng khi kéo thả trong Settings).
  Future<void> setPinnedOrder(List<String> ids) =>
      update((p) => p.copyWith(toolbarItems: ids));

  /// Hiện [id] trong bảng Công cụ soạn thảo, hoặc ẩn khỏi bảng.
  Future<void> setShownInSheet(String id, bool shown) => update((p) {
    final hidden = [...p.hiddenTools]..remove(id);
    if (!shown) hidden.add(id);
    return p.copyWith(hiddenTools: hidden);
  });
}
