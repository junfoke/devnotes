import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/locale_provider.dart';
import '../core/theme/theme_provider.dart';
import '../features/git_sync/presentation/auto_sync_scope.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

class DevNotesApp extends ConsumerWidget {
  const DevNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final localePreference = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = themeNotifier.resolveTheme(brightness);

    return MaterialApp.router(
      title: 'DevNotes',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // null = theo máy; resolveAppLocale lo phần máy dùng ngôn ngữ khác.
      locale: localePreference.locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
      builder: (context, child) =>
          AutoSyncScope(child: child ?? const SizedBox.shrink()),
    );
  }
}
