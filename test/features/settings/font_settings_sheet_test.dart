// Settings → Font phải có đủ lựa chọn như bảng "Công cụ soạn thảo", kể cả
// "Font hệ thống" — không thì chọn ở bảng xong mở Settings không thấy mục
// nào được chọn và không có cách chọn lại.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/features/settings/presentation/editor_settings_sheets.dart';
import 'package:devnotes/l10n/app_localizations.dart';
import 'package:devnotes/l10n/app_localizations_vi.dart';

void main() {
  final l = AppLocalizationsVi();

  Future<ProviderContainer> pumpSheet(
    WidgetTester tester,
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues({
      'editor_tools_migrated_v1': true,
      ...values,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final prefs = await container.read(editorPreferencesProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          theme: AppTheme.light(),
          home: Scaffold(body: FontSettingsSheet(initial: prefs)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('có "Font hệ thống", chọn thì lưu và preview bỏ fontFamily', (
    tester,
  ) async {
    await pumpSheet(tester, {});

    await tester.tap(find.text(l.editorFontSystem));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    final sp = await SharedPreferences.getInstance();
    expect(sp.getString('editor_font_family'), EditorPreferences.systemFont);
    final preview = tester.widget<Text>(find.text(l.fontPreviewSample));
    expect(preview.style!.fontFamily, isNull);
  });

  testWidgets('đang dùng font hệ thống thì mục đó được chọn', (tester) async {
    await pumpSheet(tester, {'editor_font_family': 'system'});

    final radio = tester.widget<RadioGroup<String>>(
      find.byType(RadioGroup<String>),
    );
    expect(radio.groupValue, EditorPreferences.systemFont);
    expect(find.text(l.editorFontSystem), findsOneWidget);
  });
}
