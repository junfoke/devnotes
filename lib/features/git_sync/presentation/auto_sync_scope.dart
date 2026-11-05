import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/git_sync/application/auto_sync_policy.dart';
import 'package:devnotes/features/git_sync/application/sync_controller.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';

/// Kích hoạt sync tự động theo Settings → Sync Frequency: khi mở app, khi
/// quay lại app, và theo timer định kỳ — chỉ trong lúc app đang mở.
///
/// Sync tự động không bao giờ tự mở màn hình nào: lỗi hay conflict chỉ hiện
/// ở chấm trạng thái và lịch sử sync. Xem DECISIONS.md, "Sync tự động".
///
/// Đang có editor mở thì hoãn, chạy ngay khi editor cuối cùng đóng — pull lúc
/// đang soạn làm màn hình lệch với file trên đĩa. Xem DECISIONS.md, "Editor
/// không ghi đè thay đổi từ bên ngoài".
class AutoSyncScope extends ConsumerStatefulWidget {
  const AutoSyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoSyncScope> createState() => _AutoSyncScopeState();
}

class _AutoSyncScopeState extends ConsumerState<AutoSyncScope>
    with WidgetsBindingObserver {
  Timer? _timer;

  /// Cấu hình timer đang chạy — chỉ lập lịch lại khi nó thật sự đổi, để mỗi
  /// lần đổi cỡ chữ hay kéo thanh thông báo không làm timer đếm lại từ đầu.
  (SyncFrequency, Duration)? _scheduled;

  /// Có lần sync tự động bị hoãn vì đang mở editor.
  bool _pendingAfterEditor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await ref.read(editorPreferencesProvider.future);
      if (!mounted) return;
      _schedule(prefs);
      _maybeSync(AutoSyncTrigger.appOpen);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeSync(AutoSyncTrigger.appResume);
      final prefs = ref.read(editorPreferencesProvider).valueOrNull;
      if (prefs != null) _schedule(prefs);
    } else if (state == AppLifecycleState.paused) {
      // App bị ẩn thì dừng timer — không sync nền.
      _timer?.cancel();
      _scheduled = null;
    }
  }

  void _schedule(EditorPreferences prefs) {
    final wanted = (prefs.syncFrequency, prefs.periodicInterval);
    if (_scheduled == wanted && _timer?.isActive == true) return;
    _timer?.cancel();
    _scheduled = wanted;
    if (prefs.syncFrequency != SyncFrequency.periodic) return;
    _timer = Timer.periodic(
        prefs.periodicInterval, (_) => _maybeSync(AutoSyncTrigger.timer));
  }

  Future<void> _maybeSync(AutoSyncTrigger trigger) async {
    final prefs = await ref.read(editorPreferencesProvider.future);
    if (!mounted) return;
    final now = DateTime.now();
    final run = AutoSyncPolicy.shouldRun(
      frequency: prefs.syncFrequency,
      trigger: trigger,
      lastAutoSyncAt: ref.read(lastAutoSyncAtProvider),
      now: now,
    );
    if (!run) return;
    if (ref.read(openEditorCountProvider) > 0) {
      _pendingAfterEditor = true;
      return;
    }
    await _runNow();
  }

  Future<void> _runNow() async {
    _pendingAfterEditor = false;
    ref.read(lastAutoSyncAtProvider.notifier).state = DateTime.now();
    await ref.read(syncControllerProvider).sync(auto: true);
  }

  @override
  Widget build(BuildContext context) {
    // Đổi Sync Frequency trong Settings thì lập lịch lại ngay.
    ref.listen(editorPreferencesProvider, (_, next) {
      final prefs = next.valueOrNull;
      if (prefs != null) _schedule(prefs);
    });
    // Editor cuối cùng vừa đóng mà có lần sync bị hoãn → chạy luôn.
    ref.listen(openEditorCountProvider, (_, count) {
      if (count == 0 && _pendingAfterEditor) _runNow();
    });
    return widget.child;
  }
}
