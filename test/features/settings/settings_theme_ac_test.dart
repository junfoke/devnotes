// AC-traceability widget test cho ô chọn theme trong Settings.
//   - UC-015 AC-1: chọn Dark cập nhật state + persist
//   - UC-015 AC-4: menu chọn theme không tràn khỏi mép màn hình
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#settings (theme)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/settings/presentation/settings_screen.dart';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => container.dispose());

  Future<void> pumpSettings(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UC-015 Change Theme', () {
    testWidgets('AC-4: mọi lựa chọn theme nằm trọn trong màn hình',
        (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byKey(const Key('theme-selector')));
      await tester.pumpAndSettle();

      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;

      for (final label in ['System', 'Light', 'Dark']) {
        final items = find.text(label);
        expect(items, findsWidgets, reason: 'thiếu lựa chọn "$label"');

        // Lựa chọn hiển thị trong menu bật lên phải nằm trọn trong màn hình.
        final rect = tester.getRect(items.last);
        expect(rect.left, greaterThanOrEqualTo(0.0),
            reason: '"$label" tràn mép trái');
        expect(rect.right, lessThanOrEqualTo(screenWidth),
            reason: '"$label" tràn mép phải');
      }
    });

    testWidgets('AC-1: chọn Dark cập nhật state và ghi SharedPreferences',
        (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byKey(const Key('theme-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(container.read(themeProvider), ThemePreference.dark);
      expect(prefs.getString('theme_preference'), 'dark');
    });
  });
}
