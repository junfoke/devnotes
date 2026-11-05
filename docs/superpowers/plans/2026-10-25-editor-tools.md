# Bảng "Công cụ soạn thảo" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm nút `⋯` cố định ở mép phải thanh công cụ editor, mở bottom sheet "Công cụ soạn thảo" với 19 tiện ích (hiển thị, sửa, chèn, xem nhanh) và cơ chế ghim/ẩn dùng chung với Settings → Toolbar Layout.

**Architecture:** Logic văn bản là hàm thuần trên `TextEditingValue` (`lib/features/editor/domain/`), test bằng unit test. Một registry `EditorTool` liệt kê mọi mục (nút Markdown cũ + tiện ích) với id ổn định; `EditorPreferences` lưu danh sách ghim (có thứ tự) và tập ẩn. UI: `EditorToolbar` (thay `MarkdownToolbar`) + `EditorToolsSheet` + các dialog/thanh nhỏ; `EditorScreen` điều phối qua `EditorToolRunner`. Mọi thay đổi văn bản đi qua `TextEditingController` để autosave và lớp chặn ghi đè hiện có vẫn hoạt động.

**Tech Stack:** Flutter 3.41, Riverpod 2, SharedPreferences, gen-l10n (vi + en), flutter_markdown.

**Spec:** `docs/superpowers/specs/2026-10-25-editor-tools-design.md`

## Global Constraints

- Mọi chuỗi hiển thị mới thêm vào **cả** `lib/l10n/app_vi.arb` và `lib/l10n/app_en.arb` (cùng key), rồi chạy `flutter gen-l10n`; code dùng `context.l10n` (`lib/core/l10n/l10n.dart`).
- Mọi thao tác sửa văn bản chỉ được đổi `TextEditingController.value` của editor — không ghi file trực tiếp (để listener autosave + kiểm tra "thay đổi bên ngoài" trong `editor_screen.dart` vẫn bắt được).
- Không đổi định dạng file `.md`/frontmatter. Ngoại lệ duy nhất: link giữa các note dạng `[Tiêu đề](ten-file.md)` và việc tự sửa link khi đổi tên (Task 8, ghi `DECISIONS.md`).
- Cài đặt hiển thị áp dụng cho **mọi note** (lưu trong `EditorPreferences`), không lưu riêng từng note.
- Id nút Markdown cũ giữ nguyên: `h1 h2 h3 bold italic strikethrough link image code_inline code_block checklist list_unordered list_ordered quote table hr`. Key SharedPreferences cũ `editor_toolbar_items` vẫn là danh sách **ghim** có thứ tự.
- Widget test: không I/O file thật trong `testWidgets` (dùng `test/features/editor/in_memory_note_repository.dart` hoặc `tester.runAsync`); `MaterialApp` trong test phải có `AppLocalizations.localizationsDelegates`, `supportedLocales`, `locale: Locale('vi')`.
- Chạy test bằng `flutter test --timeout 60s`; `flutter analyze` phải sạch trước mỗi commit.
- Viết file Dart bằng công cụ Edit/Write, không qua heredoc Python (escape `\n` bị hỏng).
- Commit message dạng `feat: …`/`fix: …` tiếng Việt, kết thúc bằng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Hoàn tác ngay sau khi mở note không được xóa sạch nội dung** — lịch sử hoàn tác bắt đầu sau khi note tải xong (test ở Task 4).
2. **Bấm công cụ khi note chưa tải xong / tải lỗi** — các nút sửa văn bản bị vô hiệu, không ném lỗi (test ở Task 4).
3. **Thụt lề / đưa dòng với vùng chọn nhiều dòng, dòng cuối không có `\n`, văn bản rỗng** — kết quả đúng, con trỏ/vùng chọn đi theo (test ở Task 1).
4. **Tìm & thay thế với ký tự đặc biệt regex (`.` `*` `(`) và chữ tiếng Việt có dấu, không phân biệt hoa thường** — tìm theo nghĩa đen; thay bằng chuỗi rỗng được (test ở Task 1).
5. **Tự sửa link khi đổi tên** — không đụng link nằm trong khối code, xử lý tên file có `%20`/`./`, note không đọc được thì bỏ qua và báo, không làm hỏng các note khác (test ở Task 8).

---

## File map

| File | Trách nhiệm |
|---|---|
| `lib/features/editor/domain/text_ops.dart` (mới) | Hàm thuần sửa văn bản: thụt/lùi, đưa dòng, nhân đôi/xóa dòng, chèn, bảng, khối code, tìm/thay, tiêu đề, thống kê |
| `lib/features/editor/domain/editor_tool.dart` (mới) | Registry mọi mục công cụ: id, nhóm, icon, mặc định ghim |
| `lib/features/editor/domain/note_templates.dart` (mới) | Bộ mẫu ghi chú vi/en |
| `lib/features/editor/domain/note_links.dart` (mới) | Tạo link note, đọc đích link, viết lại link khi đổi tên |
| `lib/features/settings/domain/editor_preferences.dart` | Thêm `lineHeight`, `wordWrap`, `focusMode`, `hiddenTools`; font `system` |
| `lib/features/settings/data/preferences_repository.dart` | Lưu/đọc trường mới + di trú ghim mặc định một lần |
| `lib/features/editor/presentation/widgets/editor_toolbar.dart` (thay `markdown_toolbar.dart`) | Thanh công cụ: mục ghim + nút `⋯` cố định |
| `lib/features/editor/presentation/widgets/editor_tools_sheet.dart` (mới) | Bottom sheet 5 nhóm + chế độ Tùy chỉnh |
| `lib/features/editor/presentation/widgets/find_replace_bar.dart` (mới) | Thanh tìm & thay thế phía trên thanh công cụ |
| `lib/features/editor/presentation/widgets/tool_pickers.dart` (mới) | Dialog chọn bảng, ngôn ngữ code, note để link, mẫu, mục lục |
| `lib/features/editor/presentation/editor_tool_runner.dart` (mới) | Thực thi một id công cụ trên controller của editor |
| `lib/features/editor/presentation/editor_screen.dart` | Gắn toolbar/sheet/find bar, undo controller, line height, wrap, focus mode |
| `lib/features/editor/presentation/widgets/markdown_preview.dart` | Bấm link `.md` → mở note trong app |
| `lib/features/workspace/application/workspace_providers.dart` | `NoteActions.rename` sửa link ở các note khác |
| `lib/features/settings/presentation/editor_settings_sheets.dart` | Toolbar Layout liệt kê mọi mục với công tắc ghim + ẩn |

---

### Task 1: Hàm thuần sửa văn bản

**Files:**
- Create: `lib/features/editor/domain/text_ops.dart`
- Test: `test/features/editor/text_ops_test.dart`

**Interfaces:**
- Produces (mọi hàm nhận/trả `TextEditingValue v`, vùng chọn đi theo nội dung):
  - `TextEditingValue indentLines(TextEditingValue v)` — thêm 2 dấu cách đầu mọi dòng chạm vùng chọn.
  - `TextEditingValue outdentLines(TextEditingValue v)` — bỏ tối đa 2 dấu cách (hoặc 1 tab) đầu mỗi dòng.
  - `TextEditingValue moveLines(TextEditingValue v, {required bool up})` — đưa (các) dòng chạm vùng chọn lên/xuống một dòng; ở biên thì giữ nguyên.
  - `TextEditingValue duplicateLines(TextEditingValue v)`; `TextEditingValue deleteLines(TextEditingValue v)`.
  - `TextEditingValue insertAtCursor(TextEditingValue v, String text, {bool asBlock = false})` — thay vùng chọn bằng `text`; `asBlock` thì tự thêm `\n` trước nếu không ở đầu dòng.
  - `String buildTable(List<String> headers, int rows)` — số cột = số tiêu đề; chữ tiêu đề do caller truyền (đã dịch theo ngôn ngữ).
  - `String buildCodeBlock(String language)` → "```{language}\n\n```".
  - `List<TextRange> findAll(String text, String query, {bool caseSensitive = false})` — nghĩa đen, không regex.
  - `String replaceAllLiteral(String text, String query, String replacement, {bool caseSensitive = false})`.
  - `List<({int level, String title, int offset})> headings(String text)` — `#`…`######` ngoài khối code.
  - `({int words, int chars, int readMinutes}) textStats(String text)` — 200 từ/phút, làm tròn lên, tối thiểu 1 khi có chữ, 0 khi rỗng.

- [ ] **Step 1: Viết test thất bại** — các test (tên tiếng Việt, mô tả hành vi), tối thiểu:

```dart
test('thụt lề mọi dòng trong vùng chọn, vùng chọn giãn theo', () {
  final v = TextEditingValue(text: 'a\nb\nc', selection: const TextSelection(baseOffset: 0, extentOffset: 3));
  final r = indentLines(v);
  expect(r.text, '  a\n  b\nc');
  expect(r.selection, const TextSelection(baseOffset: 2, extentOffset: 7));
});
test('lùi lề không xóa chữ khi dòng không có khoảng trắng đầu', () {
  expect(outdentLines(const TextEditingValue(text: 'abc', selection: TextSelection.collapsed(offset: 1))).text, 'abc');
});
test('đưa dòng cuối (không có \\n) lên trên', () {
  final v = const TextEditingValue(text: 'a\nb', selection: TextSelection.collapsed(offset: 3));
  expect(moveLines(v, up: true).text, 'b\na');
});
test('đưa dòng đầu lên thì giữ nguyên', () { /* text không đổi */ });
test('văn bản rỗng: mọi thao tác dòng không ném lỗi', () { /* indent/outdent/move/duplicate/delete trên '' */ });
test('tìm theo nghĩa đen với ký tự đặc biệt', () {
  expect(findAll('a.b a*b (x)', '.').length, 1);
  expect(findAll('a.b a*b (x)', '(x)').single, const TextRange(start: 8, end: 11));
});
test('tìm không phân biệt hoa thường với chữ có dấu', () {
  expect(findAll('Ghi Chú và ghi chú', 'ghi chú').length, 2);
});
test('thay hết bằng chuỗi rỗng', () { expect(replaceAllLiteral('x-y-z', '-', ''), 'xyz'); });
test('tiêu đề trong khối code bị bỏ qua', () {
  expect(headings('# A\n```\n# không\n```\n## B').map((h) => h.title), ['A', 'B']);
});
test('thống kê: 400 từ là 2 phút đọc, rỗng là 0', () { /* textStats */ });
test('bảng 3 cột 2 hàng có hàng tiêu đề và hàng phân cách', () {
  expect(buildTable(['A', 'B', 'C'], 2), '| A | B | C |\n| --- | --- | --- |\n|  |  |  |\n|  |  |  |');
});
```

- [ ] **Step 2: Chạy, xác nhận đỏ** — `flutter test test/features/editor/text_ops_test.dart` → lỗi "undefined name".
- [ ] **Step 3: Viết `text_ops.dart`** theo Interfaces. "Dòng chạm vùng chọn" = từ đầu dòng chứa `min(base, extent)` tới cuối dòng chứa `max(...)` (nếu extent đứng đúng đầu dòng sau và vùng chọn không rỗng thì không tính dòng đó). Khối code nhận diện bằng dòng bắt đầu ```` ``` ```` như `checklist_toggle.dart`.
- [ ] **Step 4: Chạy lại, xanh.**
- [ ] **Step 5: Commit** `feat: các thao tác văn bản cho công cụ soạn thảo`.

---

### Task 2: Cài đặt hiển thị mới + di trú ghim mặc định

**Files:**
- Modify: `lib/features/settings/domain/editor_preferences.dart`, `lib/features/settings/data/preferences_repository.dart`
- Test: `test/features/settings/editor_preferences_test.dart` (mới)

**Interfaces:**
- Produces trên `EditorPreferences` (có trong `copyWith`):
  - `enum EditorLineHeight { compact, normal, relaxed }` (cùng file) → hệ số `1.35 / 1.6 / 1.9`, getter `double get value`.
  - `final EditorLineHeight lineHeight` (mặc định `normal`), `final bool wordWrap` (mặc định `true`), `final bool focusMode` (mặc định `false`), `final List<String> hiddenTools` (mặc định `[]`).
  - `fontFamily` nhận thêm giá trị `EditorPreferences.systemFont = 'system'` (nghĩa: dùng font mặc định của app, tức `null` khi dựng `TextStyle`); getter `String? get fontFamilyOrNull`.
  - `static const pinnedAddedByToolsUpdate = ['undo', 'redo', 'indent', 'outdent']`; `defaultToolbarItems` = danh sách cũ + 4 id này nối ở cuối.
- Keys mới: `editor_line_height` (tên enum), `editor_word_wrap`, `editor_focus_mode`, `editor_hidden_tools`, cờ `editor_tools_migrated_v1`.

- [ ] **Step 1: Viết test thất bại** (SharedPreferences.setMockInitialValues):

```dart
test('máy mới: ghim mặc định có hoàn tác, làm lại, thụt, lùi', () async {
  SharedPreferences.setMockInitialValues({});
  final p = await PreferencesRepository().loadEditorPreferences();
  expect(p.toolbarItems, containsAllInOrder(['h1', 'undo', 'redo', 'indent', 'outdent']));
});
test('người dùng cũ đã sắp toolbar: thêm 4 nút mới một lần, giữ thứ tự cũ', () async {
  SharedPreferences.setMockInitialValues({'editor_toolbar_items': ['bold', 'h1']});
  final repo = PreferencesRepository();
  expect((await repo.loadEditorPreferences()).toolbarItems, ['bold', 'h1', 'undo', 'redo', 'indent', 'outdent']);
});
test('sau di trú, user bỏ ghim "undo" thì lần tải sau không thêm lại', () async { /* save without undo → load → không có undo */ });
test('lưu và đọc lại giãn dòng, tự xuống dòng, tập trung, mục ẩn', () async { /* roundtrip */ });
test('giá trị giãn dòng lạ trong prefs thì về normal', () async { /* 'editor_line_height': 'xyz' */ });
```

- [ ] **Step 2: Chạy, đỏ.**
- [ ] **Step 3: Cài đặt** — di trú: khi đọc, nếu có `editor_toolbar_items` đã lưu và chưa có cờ thì nối các id trong `pinnedAddedByToolsUpdate` chưa có vào cuối, lưu lại danh sách và đặt cờ; nếu chưa từng lưu thì dùng `defaultToolbarItems` và đặt cờ.
- [ ] **Step 4: Chạy lại test này + `test/features/settings`, xanh.**
- [ ] **Step 5: Commit** `feat: cài đặt giãn dòng, tự xuống dòng, chế độ tập trung và ghim mặc định mới`.

---

### Task 3: Registry công cụ + nhãn đa ngôn ngữ

**Files:**
- Create: `lib/features/editor/domain/editor_tool.dart`, `lib/features/editor/presentation/editor_tool_labels.dart`
- Modify: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; `lib/features/settings/presentation/editor_settings_sheets.dart` (thay `toolbarItemName` bằng `editorToolLabel`)
- Test: `test/features/editor/editor_tool_test.dart`

**Interfaces:**
- Produces:
  - `enum EditorToolGroup { format, display, edit, insert, view }` — `format` là nhóm "Định dạng" (nút Markdown cũ).
  - `class EditorTool { final String id; final EditorToolGroup group; final IconData icon; final String? glyph; }` (`glyph` = chữ hiện thay icon, vd `H1`).
  - `static const List<EditorTool> EditorTool.all` — 16 nút Markdown (group `format`, cùng id cũ) + tiện ích với id: display `font size_down size_up line_height word_wrap focus_mode theme`; edit `undo redo indent outdent move_up move_down duplicate_line delete_line find_replace`; insert `date_time symbols note_link template` (bảng và khối code dùng id cũ `table`, `code_block`); view `outline stats`.
  - `static EditorTool? EditorTool.byId(String id)`; `ToolbarItem? markdownItemFor(String id)` giữ cho chèn cú pháp.
  - `String editorToolLabel(AppLocalizations l, String id)` (presentation) — mọi id có nhãn.
- Ghi chú: spec đếm "cỡ chữ A−/A+", "hoàn tác/làm lại", "thụt/lùi", "lên/xuống", "nhân đôi/xóa" là một tiện ích; registry tách thành từng id để ghim riêng được.

- [ ] **Step 1: Viết test thất bại:**

```dart
test('id không trùng và mọi id cũ của toolbar vẫn còn', () {
  final ids = EditorTool.all.map((t) => t.id).toList();
  expect(ids.toSet().length, ids.length);
  expect(ids, containsAll(EditorPreferences.defaultToolbarItems));
});
test('mọi công cụ có nhãn ở cả tiếng Việt và tiếng Anh', () async {
  for (final locale in const [Locale('vi'), Locale('en')]) {
    final l = await AppLocalizations.delegate.load(locale);
    for (final t in EditorTool.all) { expect(editorToolLabel(l, t.id), isNot(t.id)); }
  }
});
test('id lạ trả về null, không ném lỗi', () { expect(EditorTool.byId('khong-co'), isNull); });
```

- [ ] **Step 2: Chạy, đỏ.** **Step 3: Cài đặt + thêm key nhãn vào hai file arb, `flutter gen-l10n`.** **Step 4: Xanh (cả `test/features/settings`).**
- [ ] **Step 5: Commit** `feat: registry công cụ soạn thảo và nhãn vi/en`.

---

### Task 4: Thanh công cụ mới + nút `⋯` + hoàn tác/thụt lề

**Files:**
- Create: `lib/features/editor/presentation/widgets/editor_toolbar.dart`, `lib/features/editor/presentation/editor_tool_runner.dart`
- Delete: `lib/features/editor/presentation/widgets/markdown_toolbar.dart` (logic chèn chuyển vào runner)
- Modify: `lib/features/editor/presentation/editor_screen.dart`
- Test: `test/features/editor/editor_toolbar_test.dart` (mới); cập nhật test editor cũ nếu đổi finder

**Interfaces:**
- Consumes: Task 1 (`indentLines`, `outdentLines`, `insertAtCursor`), Task 2 (`toolbarItems`), Task 3 (`EditorTool`).
- Produces:
  - `class EditorToolbar extends StatelessWidget { EditorToolbar({required List<String> pinnedIds, required bool enabled, required void Function(String id) onTool, required VoidCallback onOpenSheet}) }` — cuộn ngang các mục ghim; nút `⋯` (`Key('editor-tools-button')`) nằm ngoài vùng cuộn, sát mép phải, luôn bấm được.
  - `class EditorToolRunner { EditorToolRunner({required TextEditingController text, required UndoHistoryController undo, required BuildContext context, required WidgetRef ref}); Future<void> run(String id); }` — nút Markdown → chèn cú pháp như cũ (giữ hành vi B-01); `undo`/`redo` → `UndoHistoryController`; `indent`/`outdent` → Task 1. Các id chưa có ở task này thì `run` bỏ qua (các task sau bổ sung).
  - `EditorScreen` truyền `UndoHistoryController` vào `TextField.undoController`; controller này được tạo **sau** khi note tải xong (hoặc `TextField` có `key` đổi khi tải xong) để lịch sử bắt đầu từ nội dung đã tải.

- [ ] **Step 1: Viết test widget thất bại** (dùng `InMemoryNoteRepository`, `Locale('vi')`):

```dart
testWidgets('nút ⋯ luôn hiện ở thanh công cụ', (t) async { /* find.byKey(Key('editor-tools-button')) findsOneWidget */ });
testWidgets('thụt lề từ thanh công cụ thêm 2 dấu cách và được tự lưu', (t) async {
  // gõ 'a', bấm nút indent (find.byTooltip(l.toolIndent)), chờ 4s → repo có '  a'
});
testWidgets('hoàn tác ngay sau khi mở note không xóa nội dung đã tải', (t) async {
  // mở note 'noi dung', bấm undo → controller vẫn 'noi dung'
});
testWidgets('gõ rồi hoàn tác thì về nội dung trước khi gõ', (t) async { /* 'noi dung' → gõ thêm → undo → 'noi dung' */ });
testWidgets('note tải lỗi thì nút sửa văn bản bị vô hiệu, bấm không ném lỗi', (t) async {
  // repo.readNote ném lỗi → toolbar enabled == false; tap indent → takeException() isNull
});
```

- [ ] **Step 2: Chạy, đỏ.** **Step 3: Cài đặt.** **Step 4: Chạy toàn bộ `test/features/editor`, xanh.**
- [ ] **Step 5: Commit** `feat: thanh công cụ có nút công cụ, hoàn tác và thụt lề`.

---

### Task 5: Bảng "Công cụ soạn thảo" + nhóm Hiển thị + Tùy chỉnh

**Files:**
- Create: `lib/features/editor/presentation/widgets/editor_tools_sheet.dart`
- Modify: `lib/features/editor/presentation/editor_screen.dart`, arb files
- Test: `test/features/editor/editor_tools_sheet_test.dart`

**Interfaces:**
- Consumes: Task 2 (prefs), Task 3 (registry, nhãn), Task 4 (`EditorToolRunner.run`, `onOpenSheet`).
- Produces:
  - `Future<void> showEditorToolsSheet(BuildContext context, {required EditorToolRunner runner})` — `showModalBottomSheet(isScrollControlled: true)`; mở thì `FocusScope.unfocus()` (ẩn bàn phím); nhóm theo thứ tự `display, edit, insert, view, format`; mục trong `hiddenTools` không hiện; mục đang ghim vẫn hiện trong bảng (bảng là nơi đầy đủ).
  - Nhóm Hiển thị là điều khiển trực tiếp, không đóng bảng: font (3 chip: JetBrains Mono / Fira Code / Font hệ thống), cỡ chữ A−/A+ (12–24, bước 1), giãn dòng (3 chip), tự xuống dòng (switch), chế độ tập trung (switch), sáng/tối (nút; đang `system` thì chuyển sang ngược với độ sáng hiện tại). Lưu qua `preferencesRepoProvider` + `ref.invalidate(editorPreferencesProvider)` / `themeProvider`.
  - Nút "Tùy chỉnh" (`Key('tools-customize')`) đổi bảng sang chế độ có hai công tắc mỗi mục: "Ghim" (thêm/bớt ở cuối `toolbarItems`) và "Hiện trong bảng" (bớt/thêm `hiddenTools`).
  - `EditorScreen` áp dụng: `TextStyle.height = lineHeight.value`; `wordWrap == false` → `TextField` trong `SingleChildScrollView(scrollDirection: Axis.horizontal)` với chiều rộng tối thiểu bằng màn hình, `softWrap` tắt; `focusMode` → ẩn `EditorAppBar`, Back hệ thống vẫn đi qua `_leave`.

- [ ] **Step 1: Viết test thất bại:**

```dart
testWidgets('bấm ⋯ mở bảng có đủ các nhóm', (t) async { /* tiêu đề 5 nhóm hiện */ });
testWidgets('A+ trong bảng tăng cỡ chữ ô soạn ngay và lưu vào cài đặt', (t) async {
  // fontSize 14 → bấm A+ → TextField style.fontSize == 15; prefs editor_font_size == 15
});
testWidgets('chọn Font hệ thống thì ô soạn không đặt fontFamily', (t) async {});
testWidgets('tắt tự xuống dòng thì dòng dài cuộn ngang', (t) async { /* tìm SingleChildScrollView ngang chứa TextField */ });
testWidgets('chế độ tập trung ẩn thanh tiêu đề', (t) async { /* EditorAppBar findsNothing */ });
testWidgets('Tùy chỉnh: ghim "Ngày giờ" thì nó xuất hiện trên thanh công cụ', (t) async {});
testWidgets('Tùy chỉnh: ẩn "Mục lục" thì nó biến khỏi bảng nhưng Settings vẫn liệt kê', (t) async {});
```

- [ ] **Step 2: Đỏ.** **Step 3: Cài đặt.** **Step 4: Xanh (`test/features/editor`, `test/features/settings`).**
- [ ] **Step 5: Commit** `feat: bảng công cụ soạn thảo với nhóm hiển thị và chế độ tùy chỉnh`.

---

### Task 6: Nhóm Sửa — dòng và tìm & thay thế

**Files:**
- Create: `lib/features/editor/presentation/widgets/find_replace_bar.dart`
- Modify: `editor_tool_runner.dart`, `editor_screen.dart`, arb files
- Test: `test/features/editor/editor_edit_tools_test.dart`

**Interfaces:**
- Consumes: Task 1 (`moveLines`, `duplicateLines`, `deleteLines`, `findAll`, `replaceAllLiteral`), Task 4 runner.
- Produces: runner xử lý `move_up move_down duplicate_line delete_line find_replace`. `find_replace` đóng bảng và hiện `FindReplaceBar` ngay trên thanh công cụ (vẫn thấy chữ): ô tìm, ô thay, nút trước/sau (chọn kết quả trong controller), "Thay", "Thay hết", nhãn "n/m", nút đóng. Thay đổi đi qua controller.

- [ ] **Step 1: Test thất bại:**

```dart
testWidgets('đưa dòng xuống làm note thành chưa lưu rồi được tự lưu', (t) async { /* 'a\nb' con trỏ ở a → move_down → 'b\na' trên đĩa sau 4s */ });
testWidgets('tìm hiện số kết quả và chọn kết quả đầu tiên', (t) async { /* 'x y x' tìm 'x' → '1/2', selection TextRange(0,1) */ });
testWidgets('thay hết thay mọi chỗ và hoàn tác được một lần', (t) async { /* replace all rồi undo → về nội dung cũ */ });
testWidgets('đang có thay đổi bên ngoài thì lệnh sửa vẫn bị chặn ghi đè như gõ phím', (t) async {
  // repo đổi file → duplicate_line → chờ autosave → dialog "thay đổi bên ngoài" hiện, file không bị ghi đè
});
```

- [ ] **Step 2: Đỏ.** **Step 3: Cài đặt.** **Step 4: Xanh.** **Step 5: Commit** `feat: công cụ đưa dòng, nhân đôi/xóa dòng, tìm và thay thế`.

---

### Task 7: Nhóm Chèn — ngày giờ, bảng, khối code, ký tự, mẫu

**Files:**
- Create: `lib/features/editor/domain/note_templates.dart`, `lib/features/editor/presentation/widgets/tool_pickers.dart`
- Modify: `editor_tool_runner.dart`, arb files
- Test: `test/features/editor/note_templates_test.dart`, `test/features/editor/editor_insert_tools_test.dart`

**Interfaces:**
- Consumes: Task 1 (`insertAtCursor`, `buildTable`, `buildCodeBlock`), Task 4 runner.
- Produces:
  - `class NoteTemplate { final String id; final String title; final String body; }`; `List<NoteTemplate> builtInTemplates(String languageCode)` — id `meeting`, `bug_report`, `journal`; `vi` → bản tiếng Việt, khác → tiếng Anh.
  - `Future<({int columns, int rows})?> showTablePicker(BuildContext)` (2–6 cột, 1–10 hàng, mặc định 3×2); `Future<String?> showCodeLanguagePicker(BuildContext)` (danh sách: dart, kotlin, swift, js, ts, python, java, go, rust, sql, bash, json, yaml, html, css, markdown, plaintext); `Future<NoteTemplate?> showTemplatePicker(BuildContext, String languageCode)`.
  - Runner: `date_time` chèn `DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())`; `table` (id cũ) → picker → `buildTable(header tiêu đề cột theo l10n "Cột 1…", rows)` dạng block; `code_block` (id cũ) → picker → `buildCodeBlock(lang)` dạng block, con trỏ đặt ở dòng trống giữa; `symbols` → hàng chip `` ` { } [ ] ( ) | < > ~ # * _ = `` chèn tại con trỏ, bảng giữ mở; `template` → picker → chèn body dạng block.

- [ ] **Step 1: Test thất bại:**

```dart
test('mẫu có đủ bản tiếng Việt và tiếng Anh, cùng bộ id', () {
  expect(builtInTemplates('vi').map((t) => t.id), builtInTemplates('en').map((t) => t.id));
});
testWidgets('nút Bảng cũ mở bộ chọn và chèn bảng 3×2 mặc định', (t) async {});
testWidgets('Khối code chọn dart thì chèn ```dart và con trỏ nằm trong khối', (t) async {});
testWidgets('chèn ngày giờ theo dạng yyyy-MM-dd HH:mm', (t) async { /* RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}') */ });
testWidgets('hủy bộ chọn thì văn bản không đổi', (t) async {});
```

- [ ] **Step 2: Đỏ.** **Step 3: Cài đặt.** **Step 4: Xanh.** **Step 5: Commit** `feat: công cụ chèn ngày giờ, bảng, khối code, ký tự và mẫu ghi chú`.

---

### Task 8: Link giữa các note + tự sửa link khi đổi tên

**Files:**
- Create: `lib/features/editor/domain/note_links.dart`, `test/features/editor/note_links_test.dart`, `test/features/workspace/rename_rewrites_links_test.dart`
- Modify: `tool_pickers.dart` (thêm `showNotePicker`), `editor_tool_runner.dart`, `markdown_preview.dart`, `editor_screen.dart`, `lib/features/workspace/application/workspace_providers.dart`, `lib/features/workspace/presentation/workspace_screen.dart` (báo note không sửa được link), `DECISIONS.md`, arb files

**Interfaces:**
- Produces:
  - `String noteLink(String title, String fileName)` → `[title](file-name.md)`; `[`/`]` trong tiêu đề được escape bằng `\`; tên file có khoảng trắng được viết `%20`.
  - `String? linkedNoteFileName(String href)` — trả tên file nếu `href` là link tương đối tới `.md` (bỏ `./`, bỏ `#anchor`, giải mã `%XX`); có scheme (`https:` …) hoặc không phải `.md` → `null`.
  - `String rewriteNoteLinks(String content, {required String from, required String to})` — chỉ đổi đích link Markdown `](…)` trỏ tới `from` (so sau khi chuẩn hóa như trên), giữ `./` và `#anchor`, không đụng khối code, không đụng chữ thường trùng tên.
  - `Future<String?> showNotePicker(BuildContext, List<NoteFile> notes)` → `filePath`; runner `note_link` chèn `noteLink`.
  - `MarkdownPreview({…, void Function(String fileName)? onOpenNote})` — link có `linkedNoteFileName != null` gọi `onOpenNote` thay vì mở trình duyệt; `EditorScreen` mở `/editor/<path>` nếu file tồn tại, không thì snackbar l10n "Không tìm thấy note".
  - `NoteActions.rename(String filePath, String newTitle)` trả `Future<({NoteFile note, List<String> failedFiles})>`: sau khi đổi tên, duyệt `repo.listNotes()`, note nào `rewriteNoteLinks` cho kết quả khác thì `repo.saveNote`; note lỗi đọc/ghi thì ghi vào `failedFiles` và đi tiếp. Tên file cũ == mới thì không duyệt.
- DECISIONS mới: "Link giữa các note và tự sửa link khi đổi tên" (Chốt / Vì / Test) theo spec mục 6 và 6b.

- [ ] **Step 1: Test thất bại:**

```dart
test('đổi đúng đích link, giữ ./ và #anchor', () {
  expect(rewriteNoteLinks('[A](./a.md#x) [B](b.md)', from: 'a.md', to: 'a-moi.md'), '[A](./a-moi.md#x) [B](b.md)');
});
test('không đụng link trong khối code và chữ trùng tên', () {
  const s = 'a.md\n```\n[A](a.md)\n```\n[A](a.md)';
  expect(rewriteNoteLinks(s, from: 'a.md', to: 'z.md'), 'a.md\n```\n[A](a.md)\n```\n[A](z.md)');
});
test('tên file có khoảng trắng mã hóa %20 vẫn nhận ra', () {
  expect(rewriteNoteLinks('[A](ghi%20chu.md)', from: 'ghi chu.md', to: 'ghi-chu.md'), '[A](ghi-chu.md)');
});
test('link https và link không phải .md không phải link note', () {
  expect(linkedNoteFileName('https://x.com/a.md'), isNull);
  expect(linkedNoteFileName('img.png'), isNull);
  expect(linkedNoteFileName('./a.md#h'), 'a.md');
});
// rename_rewrites_links_test.dart (InMemoryNoteRepository hoặc NoteFileRepository trên thư mục tạm ngoài testWidgets):
test('đổi tên B thì link tới B trong A được sửa, note không liên quan giữ nguyên', () async {});
test('note không đọc được thì bỏ qua và nằm trong failedFiles, các note khác vẫn được sửa', () async {});
testWidgets('bấm link note trong preview mở note đó trong editor', (t) async {});
```

- [ ] **Step 2: Đỏ.** **Step 3: Cài đặt + ghi DECISIONS.** **Step 4: Xanh (toàn bộ `test/`).**
- [ ] **Step 5: Commit** `feat: link giữa các note, mở trong app và tự sửa khi đổi tên` (body nhắc DECISIONS 2026-10-25).

---

### Task 9: Nhóm Xem nhanh — mục lục và thống kê

**Files:**
- Modify: `tool_pickers.dart` (thêm `showOutline`), `editor_tool_runner.dart`, `editor_tools_sheet.dart`, `editor_screen.dart`, arb files
- Test: `test/features/editor/editor_view_tools_test.dart`

**Interfaces:**
- Consumes: Task 1 (`headings`, `textStats`).
- Produces: `outline` → danh sách tiêu đề thụt theo cấp; bấm thì đóng, chuyển về trang soạn (PageView trang 0), đặt con trỏ ở `offset` và cuộn tới. `stats` → dòng "N từ · M ký tự · ~K phút đọc" hiển thị thẳng trong bảng (ICU plural trong arb), không cần bấm.

- [ ] **Step 1: Test thất bại:**

```dart
testWidgets('mục lục liệt kê tiêu đề, bấm thì con trỏ nhảy tới đó', (t) async { /* '# A\n...\n## B' → bấm B → selection.baseOffset == offset của B */ });
testWidgets('note không có tiêu đề thì mục lục báo trống', (t) async {});
testWidgets('bảng hiện số từ và thời gian đọc', (t) async {});
```

- [ ] **Step 2: Đỏ.** **Step 3: Cài đặt.** **Step 4: Xanh.** **Step 5: Commit** `feat: mục lục và thống kê trong bảng công cụ`.

---

### Task 10: Settings → Toolbar Layout thống nhất + tài liệu

**Files:**
- Modify: `lib/features/settings/presentation/editor_settings_sheets.dart` (`ToolbarLayoutSheet`), arb files, `specs/BUSINESS_OVERVIEW.md`, `README.md`, `docs/06_backlog_chuc_nang_chet.md`, `docs/superpowers/specs/2026-10-25-editor-tools-design.md` (trạng thái → đã triển khai)
- Test: `test/features/settings/toolbar_layout_test.dart` (mới)

**Interfaces:**
- Consumes: Task 2, Task 3.
- Produces: sheet liệt kê **mọi** `EditorTool.all` theo nhóm; mục ghim nằm trên cùng theo thứ tự `toolbarItems` và kéo thả được; mỗi mục có công tắc "Ghim" và "Hiện trong bảng". Đổi ở đây phản ánh ngay ở editor và ngược lại (cùng `EditorPreferences`).

- [ ] **Step 1: Test thất bại:**

```dart
testWidgets('Toolbar Layout liệt kê cả nút Markdown và tiện ích', (t) async {});
testWidgets('bỏ ghim và ẩn một mục thì nó vẫn nằm trong danh sách Settings để bật lại', (t) async {});
testWidgets('kéo đổi thứ tự mục ghim được lưu', (t) async {});
```

- [ ] **Step 2: Đỏ.** **Step 3: Cài đặt + cập nhật tài liệu.** **Step 4: `flutter analyze` sạch, `flutter test --timeout 60s` toàn bộ xanh.**
- [ ] **Step 5: Kiểm thử trên emulator Pixel_9** (build `--target-platform android-x64 --split-per-abi`): mở note tạm → `⋯` → đổi cỡ chữ/giãn dòng/tắt xuống dòng → hoàn tác → chèn bảng/khối code/mẫu → tìm & thay → mục lục → link note + đổi tên note đích; xóa note tạm trước mọi lần sync.
- [ ] **Step 6: Commit** `feat: Toolbar Layout thống nhất với bảng công cụ` và `docs: cập nhật tài liệu sau khi thêm bảng công cụ soạn thảo`.
