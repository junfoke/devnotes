// Đổi ngôn ngữ trong Settings → Giao diện → Ngôn ngữ thì giao diện đổi ngay,
// và lựa chọn được lưu lại.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/l10n/locale_provider.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/features/settings/presentation/settings_screen.dart';
import 'package:devnotes/l10n/app_localizations.dart';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'app_locale': 'vi'});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  /// Nối MaterialApp với localeProvider giống lib/app/app.dart.
  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light(),
            locale: ref.watch(localeProvider).locale,
            supportedLocales: kSupportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeListResolutionCallback: (locales, _) =>
                resolveAppLocale(locales),
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('chọn English thì Settings hiện tiếng Anh và lưu "en"',
      (tester) async {
    await pumpSettings(tester);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Cài đặt'), findsNothing);
    expect(container.read(localeProvider), AppLocalePreference.en);
    expect(prefs.getString('app_locale'), 'en');
  });

  testWidgets('chọn lại Tiếng Việt thì giao diện về tiếng Việt',
      (tester) async {
    await prefs.setString('app_locale', 'en');
    container.dispose();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await pumpSettings(tester);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Việt').last);
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(prefs.getString('app_locale'), 'vi');
  });
}
