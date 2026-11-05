// Settings → Toolbar Layout dùng chung cấu hình với bảng "Công cụ soạn thảo":
// liệt kê mọi EditorTool.all, mục ghim nằm trên cùng và kéo đổi thứ tự được.
//
// Kế hoạch: docs/superpowers/plans/2026-10-25-editor-tools.md, Task 10.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/domain/editor_tool.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/presentation/editor_settings_sheets.dart';
import 'package:devnotes/l10n/app_localizations.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpSheet(
    WidgetTester tester,
    Map<String, Object> values,
  ) async {
    // Bỏ qua di trú một lần (nó tự thêm 4 nút chỉnh sửa lên đầu danh sách ghim).
    SharedPreferences.setMockInitialValues({
      'editor_tools_migrated_v1': true,
      ...values,
    });
    // Đủ cao để mọi hàng được dựng (danh sách có 38 công cụ).
    tester.view.physicalSize = const Size(800, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    container = ProviderContainer();
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
          home: Scaffold(body: ToolbarLayoutSheet(initial: prefs)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Chờ lần lưu bất đồng bộ (SharedPreferences mock) xong rồi dựng lại.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Switch switchOf(WidgetTester tester, String key) =>
      tester.widget<Switch>(find.byKey(Key(key)));

  testWidgets('Toolbar Layout liệt kê cả nút Markdown và tiện ích', (t) async {
    await pumpSheet(t, {});

    expect(EditorTool.all.length, greaterThan(16));
    for (final tool in EditorTool.all) {
      expect(
        find.byKey(Key('pin-${tool.id}')),
        findsOneWidget,
        reason: 'thiếu công tắc Ghim của ${tool.id}',
      );
      expect(
        find.byKey(Key('show-${tool.id}')),
        findsOneWidget,
        reason: 'thiếu công tắc Hiện trong bảng của ${tool.id}',
      );
    }
    // Mặc định: nút Markdown h1 được ghim, nút nhóm Hiển thị thì không.
    expect(switchOf(t, 'pin-h1').value, isTrue);
    expect(switchOf(t, 'pin-undo').value, isTrue);
    expect(switchOf(t, 'pin-word_wrap').value, isFalse);
    expect(switchOf(t, 'show-word_wrap').value, isTrue);
  });

  testWidgets(
    'bỏ ghim và ẩn một mục thì nó vẫn nằm trong danh sách Settings để bật lại',
    (t) async {
      await pumpSheet(t, {});

      await t.tap(find.byKey(const Key('pin-h1')));
      await settle(t);
      await t.tap(find.byKey(const Key('show-h1')));
      await settle(t);

      // Đã lưu: không ghim, ẩn khỏi bảng.
      final saved = await container.read(editorPreferencesProvider.future);
      expect(saved.toolbarItems, isNot(contains('h1')));
      expect(saved.hiddenTools, contains('h1'));

      // Nhưng Settings vẫn liệt kê và hai công tắc đều tắt, bật lại được.
      expect(switchOf(t, 'pin-h1').value, isFalse);
      expect(switchOf(t, 'show-h1').value, isFalse);

      await t.tap(find.byKey(const Key('show-h1')));
      await settle(t);
      await t.tap(find.byKey(const Key('pin-h1')));
      await settle(t);

      final back = await container.read(editorPreferencesProvider.future);
      expect(back.toolbarItems, contains('h1'));
      expect(back.hiddenTools, isNot(contains('h1')));
      expect(switchOf(t, 'pin-h1').value, isTrue);
    },
  );

  testWidgets('mục đã ẩn khỏi bảng từ trước vẫn có trong Settings', (t) async {
    await pumpSheet(t, {
      'editor_hidden_tools': ['stats', 'word_wrap'],
    });

    expect(find.byKey(const Key('show-stats')), findsOneWidget);
    expect(switchOf(t, 'show-stats').value, isFalse);
    expect(switchOf(t, 'show-word_wrap').value, isFalse);
    // Công tắc vẫn bật lại được.
    await t.tap(find.byKey(const Key('show-stats')));
    await settle(t);
    final saved = await container.read(editorPreferencesProvider.future);
    expect(saved.hiddenTools, ['word_wrap']);
  });

  testWidgets('mục ghim nằm trên cùng theo thứ tự toolbarItems', (t) async {
    await pumpSheet(t, {
      'editor_toolbar_items': ['bold', 'undo', 'h1'],
    });

    double y(String id) => t.getTopLeft(find.byKey(Key('pin-$id'))).dy;
    expect(y('bold'), lessThan(y('undo')));
    expect(y('undo'), lessThan(y('h1')));
    // Mục chưa ghim nằm dưới mục ghim cuối.
    expect(y('h1'), lessThan(y('italic')));
    expect(y('h1'), lessThan(y('word_wrap')));
  });

  testWidgets('kéo đổi thứ tự mục ghim được lưu', (t) async {
    await pumpSheet(t, {
      'editor_toolbar_items': ['bold', 'undo', 'h1'],
    });

    final list = t.widget<ReorderableListView>(
      find.byKey(const Key('pinned-list')),
    );
    // Kéo "bold" (0) xuống sau "h1" (newIndex = 3 theo quy ước của Flutter).
    list.onReorder(0, 3);
    await settle(t);

    final saved = await container.read(editorPreferencesProvider.future);
    expect(saved.toolbarItems, ['undo', 'h1', 'bold']);
    expect(
      t.getTopLeft(find.byKey(const Key('pin-bold'))).dy,
      greaterThan(t.getTopLeft(find.byKey(const Key('pin-h1'))).dy),
    );
  });

  testWidgets('kéo thả thật trên tay cầm cũng đổi thứ tự', (t) async {
    await pumpSheet(t, {
      'editor_toolbar_items': ['bold', 'undo', 'h1'],
    });

    final handle = find.byKey(const Key('drag-bold'));
    expect(handle, findsOneWidget);
    final gesture = await t.startGesture(t.getCenter(handle));
    await t.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 120));
    await t.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await settle(t);

    final saved = await container.read(editorPreferencesProvider.future);
    expect(saved.toolbarItems.first, isNot('bold'));
    expect(saved.toolbarItems.toSet(), {'bold', 'undo', 'h1'});
  });
}
