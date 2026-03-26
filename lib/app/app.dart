import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';
import 'router.dart';

class DevNotesApp extends ConsumerWidget {
  const DevNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final router = ref.watch(routerProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = themeNotifier.resolveTheme(brightness);

    return MaterialApp.router(
      title: 'DevNotes',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
