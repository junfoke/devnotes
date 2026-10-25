import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/application/auto_sync_policy.dart';
import 'package:devnotes/features/git_sync/application/sync_controller.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';

/// Kích hoạt sync tự động theo Settings → Sync Frequency: khi mở app, khi
/// quay lại app, và theo timer định kỳ — chỉ trong lúc app đang mở.
///
/// Sync tự động không bao giờ tự mở màn hình nào: lỗi hay conflict chỉ hiện
/// ở chấm trạng thái và lịch sử sync. Xem DECISIONS.md, "Sync tự động".
class AutoSyncScope extends ConsumerStatefulWidget {
  const AutoSyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoSyncScope> createState() => _AutoSyncScopeState();
}

class _AutoSyncScopeState extends ConsumerState<AutoSyncScope>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await ref.read(editorPreferencesProvider.future);
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
    }
  }

  void _schedule(EditorPreferences prefs) {
    _timer?.cancel();
    if (prefs.syncFrequency != SyncFrequency.periodic) return;
    _timer = Timer.periodic(
        prefs.periodicInterval, (_) => _maybeSync(AutoSyncTrigger.timer));
  }

  Future<void> _maybeSync(AutoSyncTrigger trigger) async {
    final prefs = await ref.read(editorPreferencesProvider.future);
    final now = DateTime.now();
    final run = AutoSyncPolicy.shouldRun(
      frequency: prefs.syncFrequency,
      trigger: trigger,
      lastAutoSyncAt: ref.read(lastAutoSyncAtProvider),
      now: now,
    );
    if (!run || !mounted) return;
    ref.read(lastAutoSyncAtProvider.notifier).state = now;
    await ref.read(syncControllerProvider).sync(auto: true);
  }

  @override
  Widget build(BuildContext context) {
    // Đổi Sync Frequency trong Settings thì lập lịch lại ngay.
    ref.listen(editorPreferencesProvider, (_, next) {
      final prefs = next.valueOrNull;
      if (prefs != null) _schedule(prefs);
    });
    return widget.child;
  }
}
