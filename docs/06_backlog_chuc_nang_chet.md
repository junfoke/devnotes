# Backlog — Chức năng chết & lỗi nghiêm trọng cần triển khai

> Lập ngày **2026-08-10** từ đợt kiểm thử trực tiếp trên emulator Pixel 9 (Android 16).
> Mỗi mục ghi rõ: hiện trạng đã kiểm chứng, vị trí code, và nghiệp vụ liên quan.
>
> **Cập nhật 2026-08-10 (chiều):** đã xong B-02, B-03, B-04, B-05, B-12 — xem phần
> "Đã hoàn thành" ở cuối. Phát hiện thêm B-14. Tài liệu này là phần **còn lại**.

## Cách đọc mức ưu tiên

| Mức | Nghĩa |
|-----|-------|
| **P0** | Mất dữ liệu hoặc chức năng lõi không dùng được. Làm trước. |
| **P1** | Chức năng đã có UI nhưng không chạy — user bấm vào thấy "app hỏng". |
| **P2** | Thiếu tiện ích / nợ kỹ thuật, chưa chặn người dùng. |

---

## P0 — Mất dữ liệu & chức năng lõi

### B-01. Toolbar Markdown không được lưu → mất dữ liệu

- **Hiện trạng (đã kiểm chứng):** Mở note → bấm **B** → chuỗi `****` được chèn. Thoát ra rồi mở lại → `****` biến mất.
- **Nguyên nhân:** `MarkdownToolbar._insertSyntax` gán trực tiếp `textController.value`. Gán trực tiếp **không** kích hoạt `TextField.onChanged`, nên `_onTextChanged` không chạy → `saveStatus` vẫn là `saved` → timer autosave 3 giây không được đặt. Nút Back cũng bỏ qua lưu vì điều kiện là `saveStatus != saved`.
- **Code:** [`markdown_toolbar.dart:38`](../lib/features/editor/presentation/widgets/markdown_toolbar.dart#L38), [`editor_screen.dart:117`](../lib/features/editor/presentation/editor_screen.dart#L117)
- **Hướng xử lý đề xuất:** `MarkdownToolbar` nhận thêm callback `onChanged` và gọi sau khi cập nhật controller; hoặc `EditorScreen` đăng ký `_textController.addListener` thay vì chỉ dựa vào `onChanged`. Cách thứ hai bịt được **mọi** đường sửa text lập trình, không chỉ toolbar.
- **Hành vi cần có:** sau khi chèn cú pháp từ toolbar, `saveStatus` phải chuyển sang `unsaved` và nội dung phải được ghi xuống file sau debounce.

### ✅ B-02. Sync thất bại: `GIT_ERROR_INVALID: Incorrect credentials` — XONG 2026-08-10

- **Hiện trạng (đã kiểm chứng):** Bấm **Sync Now** → chấm trạng thái git chuyển đỏ, snackbar báo lỗi trên.
- **Phân tích:** Thông điệp này do `git2dart` phát ra ở `remote_callbacks.dart:166` khi libgit2 phải hỏi credential tới lần thứ 3 — tức GitHub đã **từ chối** username/PAT hai lần. Đây là **PAT sai / hết hạn / thiếu scope `repo`**, không phải lỗi logic git trong app.
- **Việc cần làm:** cấp lại PAT và nhập lại trong Settings → Git Repository. Sau đó chạy lại kiểm thử sync đầu-cuối (pull → commit → push → conflict).
- **Lỗi app thật kèm theo:** xem B-03.

### ✅ B-03. Git Setup lưu credential mà không kiểm tra kết nối — XONG 2026-08-10

- **Hiện trạng (đã kiểm chứng):** Nhấn "Update Credentials" → snackbar *"Git credentials saved successfully"* dù credential sai. User chỉ phát hiện sai khi bấm Sync.
- **Code:** [`git_setup_screen.dart:48-74`](../lib/features/git_sync/presentation/git_setup_screen.dart#L48-L74)
- **Hướng xử lý đề xuất:** thêm nút **"Kiểm tra kết nối"** gọi `Remote.lookup(...).ls()` hoặc một `fetch` khô với credential vừa nhập; hiển thị kết quả thành công/thất bại kèm thông điệp tiếng Việt dễ hiểu (phân biệt: sai PAT / repo không tồn tại / không có mạng). Chỉ đổi nhãn thành "đã kết nối" khi kiểm tra pass.
- **Hành vi cần có:** Given PAT sai → When nhấn Kiểm tra kết nối → Then hiện lỗi cụ thể và không đánh dấu repo là đã kết nối.

### ✅ B-04. Lịch sử đồng bộ luôn rỗng — XONG 2026-08-10

- **Hiện trạng (đã kiểm chứng):** Sau 2 lần sync (đều lỗi), sheet "Sync History" vẫn hiện *"No sync history yet"*.
- **Nguyên nhân:** `SyncService` **có** ghi log vào SQLite qua `MetadataDatabase.addSyncLogEntry`, nhưng UI đọc `syncStateProvider.history` — một danh sách trong bộ nhớ. `SyncStateNotifier.addHistory()` **không bao giờ được gọi** ở đâu, và `MetadataDatabase.getSyncLog()` **không được đọc** ở đâu.
- **Code:** [`git_providers.dart:37`](../lib/features/git_sync/application/git_providers.dart#L37), [`metadata_database.dart:85`](../lib/core/file_system/metadata_database.dart#L85), [`workspace_screen.dart:252`](../lib/features/workspace/presentation/workspace_screen.dart#L252)
- **Hướng xử lý đề xuất:** biến sheet thành nguồn đọc thẳng từ `MetadataDatabase.getSyncLog()` (đã persist, sống qua khởi động lại) và bỏ danh sách in-memory, thay vì duy trì hai nguồn sự thật.

### ✅ B-05. Chấm trạng thái git luôn xanh khi mở app — XONG 2026-08-10

- **Hiện trạng (đã kiểm chứng):** Mở app lần đầu → chấm cạnh nút Sync màu xanh ("đã đồng bộ") dù chưa sync lần nào trong phiên.
- **Nguyên nhân:** `SyncStateNotifier` khởi tạo với `status: SyncStatus.synced`.
- **Code:** [`git_providers.dart:26-29`](../lib/features/git_sync/application/git_providers.dart#L26-L29)
- **Hướng xử lý đề xuất:** khởi tạo `SyncStatus.idle` (chưa rõ trạng thái) và chỉ chuyển `synced` sau một lần sync thành công; hoặc khôi phục trạng thái từ bản ghi sync log gần nhất khi khởi động.

---

## P1 — UI có nhưng bấm không chạy

### B-06. Nút ⋮ trong Editor không làm gì

- **Hiện trạng (đã kiểm chứng):** Bấm → không có phản hồi nào.
- **Code:** [`editor_screen.dart:120`](../lib/features/editor/presentation/editor_screen.dart#L120) — `onMore: () { /* TODO */ }`
- **Nội dung dự kiến (theo comment trong code):** chia sẻ, xem thông tin note, xóa note.
- **Cần làm trước khi code:** chốt menu này gồm những gì (chia sẻ / thông tin / xóa) rồi mới code.

### B-07. Năm mục Settings không có hành vi

Tất cả đều là `onTap: () {}` trong [`settings_screen.dart`](../lib/features/settings/presentation/settings_screen.dart):

| Mục | Dòng | Ghi chú |
|-----|------|---------|
| Sync Frequency | 52 | Cần UC mới: chu kỳ tự động sync, sync khi mở app / theo khoảng thời gian. |
| Font & Size | 54 | `EditorPreferences` + `preferences_repository` đã tồn tại, chỉ thiếu màn hình. |
| Toolbar Layout | 55 | `ToolbarItem.allItems` + `visibleItemIds` đã có sẵn, chỉ thiếu UI chọn/sắp xếp. |
| Rebuild Search Index | 91 | `SearchEngine.rebuildIndex()` đã có, chỉ cần gọi + hiện tiến trình. |
| Manage Collections | 93 | Cần UI sửa/xóa collection — xem B-09. |

> Lưu ý: hai mục *Font & Size* và *Toolbar Layout* gần như chỉ thiếu màn hình — phần dữ liệu và logic đã sẵn sàng, chi phí thấp nhất trong nhóm này.

### B-08. Export Notes ghi vào thư mục user không truy cập được

- **Hiện trạng (đã kiểm chứng):** Bấm Export → snackbar *"Exported to /data/user/0/com.devnotes.devnotes/cache/devnotes_export.zip"*. Đây là cache riêng của app — user không mở được bằng trình quản lý file.
- **Code:** [`settings_screen.dart:60-81`](../lib/features/settings/presentation/settings_screen.dart#L60-L81)
- **Hướng xử lý đề xuất:** `share_plus` **đã có trong `pubspec.yaml`** — sau khi tạo zip thì mở share sheet (`SharePlus.instance.share`) để user lưu ra Drive/Files/gửi đi. Định nghĩa lại cho đúng: xuất thành công nghĩa là user **nhận được** file.

### B-09. Collection không sửa/xóa được

- **Hiện trạng (đã kiểm chứng):** Tạo collection "Work" và lọc note hoạt động tốt. Nhưng nhấn giữ chip collection không có menu nào; không có đường nào để đổi tên, đổi filter tag, hay xóa.
- **Code:** [`collections_row.dart`](../lib/features/workspace/presentation/widgets/collections_row.dart) — chip chỉ có `onTap`.
- **Hướng xử lý đề xuất:** nhấn giữ chip → bottom sheet Sửa/Xóa (giống context menu của note đã có sẵn ở `workspace_screen._showNoteContextMenu`), cộng thêm màn hình "Manage Collections" ở B-07. Cần quyết định nghiệp vụ: xóa collection thì các note bên trong xử lý ra sao (chỉ bỏ nhóm, không xóa note — cần xác nhận).

### B-10. Import Notes chỉ hiện "coming soon"

- **Hiện trạng (đã kiểm chứng):** Snackbar *"Import from Files app coming soon"*.
- **Code:** [`settings_screen.dart:82-89`](../lib/features/settings/presentation/settings_screen.dart#L82-L89)
- **Cần quyết định nghiệp vụ trước khi code:** khi file trong zip trùng tên với note đang có → ghi đè, bỏ qua, hay tạo bản sao? (hiện chưa chốt.)

---

### B-14. Repo local nằm trên `master` trong khi cấu hình ghi `main`

- **Hiện trạng (đã kiểm chứng 2026-08-10):** `.git/HEAD` → `refs/heads/master`; chỉ có mỗi
  branch `master`; remote-tracking cũng chỉ có `origin/master`. Nhưng ô Branch trong
  Settings hiển thị `main`, và nút kiểm tra kết nối xác nhận remote **có** branch `main`.
  Tức repo trên GitHub đang có cả hai nhánh, còn ghi chú thì nằm ở `master`.
- **Nguyên nhân:** `initializeRepo` thoát sớm khi `.git` đã tồn tại, nên giá trị Branch chỉ
  có tác dụng đúng một lần lúc tạo repo. Repo này được tạo *trước* commit `dfa9dbc`
  (chuyển default sang `main`), lúc đó libgit2 dùng mặc định `master`. Sau đó `pull`/`push`
  đều lấy branch từ `repo.head` chứ không từ cấu hình.
- **Hệ quả:** ô Branch trong Settings hiển thị một giá trị không phản ánh thực tế. Người
  dùng đổi giá trị đó cũng không có tác dụng gì.
- **Code:** [`git2dart_client.dart`](../lib/core/git_client/git2dart_client.dart) — `pull`,
  `push`, `initializeRepo`
- **Cần chốt nghiệp vụ trước khi sửa:** khi branch local lệch branch cấu hình thì (a) đổi
  branch local theo cấu hình, (b) cập nhật cấu hình theo local, hay (c) chỉ cảnh báo?
  Đây là quyết định đụng dữ liệu — ghi vào `DECISIONS.md` sau khi chốt.

## P2 — Nợ kỹ thuật & tiện ích

### B-11. Git chạy trên main thread → UI đơ khi sync

- **Hiện trạng:** log Flutter báo *"Skipped 41 frames! The application may be doing too much work on its main thread"* trong lúc sync.
- **Khác biệt với thiết kế:** spec `docs/` ghi *"All git operations run in `Isolate.run()` to avoid blocking UI"* — code hiện **không** dùng isolate.
- **Code:** [`git2dart_client.dart`](../lib/core/git_client/git2dart_client.dart) (toàn bộ), gọi từ [`sync_service.dart`](../lib/features/git_sync/application/sync_service.dart)
- **Ghi chú:** đây là refactor lớn (git2dart dùng FFI, con trỏ native không truyền được qua isolate — phải để cả vòng đời `Repository` nằm trong isolate). Nên làm **sau khi** B-02 được giải quyết để có thể kiểm thử sync thật.

### ✅ B-12. Branch hiển thị luôn là "main" — XONG 2026-08-10

- **Nguyên nhân:** `SyncStateNotifier.setBranch()` không được gọi ở đâu; `Git2dartClient.currentBranch()` có sẵn nhưng không dùng.
- **Code:** [`git_providers.dart:40`](../lib/features/git_sync/application/git_providers.dart#L40)

### B-13. Lưu thất bại bị nuốt im lặng

- **Nguyên nhân:** `EditorScreen._loadNote()` bắt exception và bỏ qua; `_save()` không có nhánh lỗi. Ghi thất bại thì UI kẹt ở trạng thái `saving` mà không báo gì.
- **Code:** [`editor_screen.dart:69-71`](../lib/features/editor/presentation/editor_screen.dart#L69-L71)

---

## Thứ tự triển khai đề xuất

1. **B-01** — mất dữ liệu, sửa rẻ, ảnh hưởng mọi lần dùng toolbar. ← *tiếp theo*
2. ~~B-02 + B-03~~ — xong 2026-08-10.
3. ~~B-04 + B-05 + B-12~~ — xong 2026-08-10.
3b. **B-14** — lệch branch, cần chốt nghiệp vụ trước.
4. **B-07** (Font & Size, Toolbar Layout, Rebuild Search Index) — chi phí thấp, dữ liệu đã sẵn sàng.
5. **B-08** — share sheet, `share_plus` đã có sẵn.
6. **B-09 + B-06 + B-10** — cần chốt nghiệp vụ trước (xóa collection, ghi đè khi import, nội dung menu ⋮).
7. **B-11** — refactor lớn, làm cuối.
