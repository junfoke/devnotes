# Backlog — Chức năng chết & lỗi nghiêm trọng cần triển khai

> Lập ngày **2026-08-10** từ đợt kiểm thử trực tiếp trên emulator Pixel 9 (Android 16).
> Mỗi mục ghi rõ: hiện trạng đã kiểm chứng, vị trí code, và nghiệp vụ liên quan.
>
> **Cập nhật 2026-08-10 (chiều):** đã xong B-02, B-03, B-04, B-05, B-12 — xem phần
> "Đã hoàn thành" ở cuối. Phát hiện thêm B-14. Tài liệu này là phần **còn lại**.
>
> **Cập nhật 2026-10-24:** xong B-01, B-08, B-13 và 3/5 mục của B-07 (Font & Size,
> Toolbar Layout, Rebuild Search Index) — đã chạy thật trên emulator Pixel 9. Phát hiện
> và sửa B-15 (file font rỗng). Phát hiện B-16 (zip slip khi import). Còn lại: các mục
> **cần chốt nghiệp vụ** (B-14, B-09, B-06, B-10, Sync Frequency) và B-11.
>
> **Cập nhật 2026-10-24 (tối):** user chốt xong nghiệp vụ → đã làm **toàn bộ** B-06, B-07,
> B-09, B-10, B-11, B-14, B-16 (quyết định ghi trong `DECISIONS.md`, ngày 2026-10-24).
> Sửa thêm: sync luôn push để không kẹt commit. Phát hiện B-17 (PAT trên emulator hết hạn).
> Backlog **không còn mục code nào mở** — xem "Việc tiếp theo" ở cuối.
>
> **Cập nhật 2026-10-25:** user cấp PAT mới → kiểm thử đầu-cuối trên emulator **đạt**: sync,
> chuyển `master` → `main` qua màn conflict, `main` trên GitHub có đủ 5 note (merge commit
> hai cha), `master` giữ nguyên. Trong lúc thử phát hiện và sửa B-18; còn mở B-19, B-20.

## Cách đọc mức ưu tiên

| Mức | Nghĩa |
|-----|-------|
| **P0** | Mất dữ liệu hoặc chức năng lõi không dùng được. Làm trước. |
| **P1** | Chức năng đã có UI nhưng không chạy — user bấm vào thấy "app hỏng". |
| **P2** | Thiếu tiện ích / nợ kỹ thuật, chưa chặn người dùng. |

---

## P0 — Mất dữ liệu & chức năng lõi

### ✅ B-01. Toolbar Markdown không được lưu → mất dữ liệu — XONG 2026-10-24

> Sửa bằng `_textController.addListener` (bịt mọi đường sửa text bằng code), so với nội
> dung lần trước để việc chỉ dời con trỏ không bị tính là sửa. Test:
> `test/features/editor/editor_autosave_test.dart`.

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

### ✅ B-06. Nút ⋮ trong Editor không làm gì — XONG 2026-10-24

> Menu Chia sẻ (share file .md) / Thông tin (file, tags, ngày, số từ) / Xóa (xác nhận; chặn autosave ghi lại file vừa xóa). Test: `test/features/editor/editor_more_menu_test.dart`.

- **Hiện trạng (đã kiểm chứng):** Bấm → không có phản hồi nào.
- **Code:** [`editor_screen.dart:120`](../lib/features/editor/presentation/editor_screen.dart#L120) — `onMore: () { /* TODO */ }`
- **Nội dung dự kiến (theo comment trong code):** chia sẻ, xem thông tin note, xóa note.
- **Cần làm trước khi code:** chốt menu này gồm những gì (chia sẻ / thông tin / xóa) rồi mới code.

### ✅ B-07. Năm mục Settings không có hành vi — XONG 2026-10-24

> Thêm Sync Frequency (Thủ công / Khi mở app / Định kỳ) và Manage Collections (`/settings/collections`).

> ✅ Font & Size (bottom sheet chọn JetBrainsMono/FiraCode + slider 12–24), ✅ Toolbar
> Layout (bật/tắt + kéo đổi thứ tự; toolbar giờ hiện theo thứ tự đã lưu), ✅ Rebuild
> Search Index. **Còn:** Sync Frequency (đụng git sync → cần chốt), Manage Collections
> (đi cùng B-09).

Tất cả đều là `onTap: () {}` trong [`settings_screen.dart`](../lib/features/settings/presentation/settings_screen.dart):

| Mục | Dòng | Ghi chú |
|-----|------|---------|
| Sync Frequency | 52 | Cần UC mới: chu kỳ tự động sync, sync khi mở app / theo khoảng thời gian. |
| Font & Size | 54 | `EditorPreferences` + `preferences_repository` đã tồn tại, chỉ thiếu màn hình. |
| Toolbar Layout | 55 | `ToolbarItem.allItems` + `visibleItemIds` đã có sẵn, chỉ thiếu UI chọn/sắp xếp. |
| Rebuild Search Index | 91 | `SearchEngine.rebuildIndex()` đã có, chỉ cần gọi + hiện tiến trình. |
| Manage Collections | 93 | Cần UI sửa/xóa collection — xem B-09. |

> Lưu ý: hai mục *Font & Size* và *Toolbar Layout* gần như chỉ thiếu màn hình — phần dữ liệu và logic đã sẵn sàng, chi phí thấp nhất trong nhóm này.

### ✅ B-08. Export Notes ghi vào thư mục user không truy cập được — XONG 2026-10-24

> Sau khi tạo zip thì mở share sheet (`Share.shareXFiles`, share_plus 10.1.4).

- **Hiện trạng (đã kiểm chứng):** Bấm Export → snackbar *"Exported to /data/user/0/com.devnotes.devnotes/cache/devnotes_export.zip"*. Đây là cache riêng của app — user không mở được bằng trình quản lý file.
- **Code:** [`settings_screen.dart:60-81`](../lib/features/settings/presentation/settings_screen.dart#L60-L81)
- **Hướng xử lý đề xuất:** `share_plus` **đã có trong `pubspec.yaml`** — sau khi tạo zip thì mở share sheet (`SharePlus.instance.share`) để user lưu ra Drive/Files/gửi đi. Định nghĩa lại cho đúng: xuất thành công nghĩa là user **nhận được** file.

### ✅ B-09. Collection không sửa/xóa được — XONG 2026-10-24

> Nhấn giữ chip → Edit/Delete; màn Manage Collections. Xóa chỉ bỏ nhóm, note giữ nguyên.

- **Hiện trạng (đã kiểm chứng):** Tạo collection "Work" và lọc note hoạt động tốt. Nhưng nhấn giữ chip collection không có menu nào; không có đường nào để đổi tên, đổi filter tag, hay xóa.
- **Code:** [`collections_row.dart`](../lib/features/workspace/presentation/widgets/collections_row.dart) — chip chỉ có `onTap`.
- **Hướng xử lý đề xuất:** nhấn giữ chip → bottom sheet Sửa/Xóa (giống context menu của note đã có sẵn ở `workspace_screen._showNoteContextMenu`), cộng thêm màn hình "Manage Collections" ở B-07. Cần quyết định nghiệp vụ: xóa collection thì các note bên trong xử lý ra sao (chỉ bỏ nhóm, không xóa note — cần xác nhận).

### ✅ B-10. Import Notes chỉ hiện "coming soon" — XONG 2026-10-24

> Chọn zip bằng `file_picker` → nhập theo quyết định "trùng tên thì tạo bản sao" → dialog tóm tắt. Đã thử thật trên emulator.

- **Hiện trạng (đã kiểm chứng):** Snackbar *"Import from Files app coming soon"*.
- **Code:** [`settings_screen.dart:82-89`](../lib/features/settings/presentation/settings_screen.dart#L82-L89)
- **Cần quyết định nghiệp vụ trước khi code:** khi file trong zip trùng tên với note đang có → ghi đè, bỏ qua, hay tạo bản sao? (hiện chưa chốt.)
- **Phải sửa B-16 cùng lúc** — không được mở UI Import khi chưa chặn zip slip.

---

### ✅ B-14. Repo local nằm trên `master` trong khi cấu hình ghi `main` — XONG 2026-10-24

> Cảnh báo ở Git Setup + nút chuyển (merge branch cũ vào, giữ branch cũ). **Chưa bấm chuyển trên emulator** vì sẽ push lên repo GitHub thật — để user tự bấm khi đã cấp PAT mới (B-17).

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

### ✅ B-16. Import ZIP không chặn path traversal (zip slip) — XONG 2026-10-24

- **Hiện trạng (đọc code 2026-10-24):** `importFromZip` ghi thẳng `'$workspacePath/${file.name}'`.
  Zip có mục tên `../../shared_prefs/x.md` sẽ ghi ra ngoài workspace — đè dữ liệu app.
  Chưa khai thác được vì Import chưa có UI (B-10), nhưng sẽ thành lỗ hổng ngay khi B-10 xong.
- **Code:** [`export_import_service.dart`](../lib/features/settings/data/export_import_service.dart) — `importFromZip`
- **Hướng xử lý:** chuẩn hóa đường dẫn đích bằng `p.normalize`, bỏ qua mục nào không nằm
  trong `workspacePath` (`p.isWithin`). Viết test với zip chứa `../`.

## P2 — Nợ kỹ thuật & tiện ích

### ✅ B-11. Git chạy trên main thread → UI đơ khi sync — XONG 2026-10-24

> `Git2dartClient` giờ là lớp vỏ chạy mọi thao tác qua `Isolate.run`; logic nằm ở `Git2dartOps`. Đã xác nhận trên Android (log "git chạy trong isolate phụ"). Commit `a026ca1` từng gỡ isolate với lý do "FFI không nạp được" — nhiều khả năng chẩn đoán nhầm (lỗi thật là unborn branch). Phòng hờ: không nạp được libgit2 trong isolate thì tự chạy trên main.

- **Hiện trạng:** log Flutter báo *"Skipped 41 frames! The application may be doing too much work on its main thread"* trong lúc sync.
- **Khác biệt với thiết kế:** spec `docs/` ghi *"All git operations run in `Isolate.run()` to avoid blocking UI"* — code hiện **không** dùng isolate.
- **Code:** [`git2dart_client.dart`](../lib/core/git_client/git2dart_client.dart) (toàn bộ), gọi từ [`sync_service.dart`](../lib/features/git_sync/application/sync_service.dart)
- **Ghi chú:** đây là refactor lớn (git2dart dùng FFI, con trỏ native không truyền được qua isolate — phải để cả vòng đời `Repository` nằm trong isolate). Nên làm **sau khi** B-02 được giải quyết để có thể kiểm thử sync thật.

### ✅ B-12. Branch hiển thị luôn là "main" — XONG 2026-08-10

- **Nguyên nhân:** `SyncStateNotifier.setBranch()` không được gọi ở đâu; `Git2dartClient.currentBranch()` có sẵn nhưng không dùng.
- **Code:** [`git_providers.dart:40`](../lib/features/git_sync/application/git_providers.dart#L40)

### ✅ B-13. Lưu thất bại bị nuốt im lặng — XONG 2026-10-24

> Ghi lỗi → snackbar "Không lưu được ghi chú", trạng thái về `unsaved`; bấm Back khi lưu
> lỗi thì **ở lại** editor thay vì thoát và bỏ nội dung. Test:
> `test/features/editor/editor_save_error_test.dart`.

- **Nguyên nhân:** `EditorScreen._loadNote()` bắt exception và bỏ qua; `_save()` không có nhánh lỗi. Ghi thất bại thì UI kẹt ở trạng thái `saving` mà không báo gì.
- **Code:** [`editor_screen.dart:69-71`](../lib/features/editor/presentation/editor_screen.dart#L69-L71)

---

### ✅ B-15. File font trong `assets/fonts/` rỗng (0 byte) — XONG 2026-10-24

- Cả 4 file `.ttf` là placeholder 0 byte từ lúc dựng project → editor chưa bao giờ hiện
  font monospace, chọn font nào cũng ra font mặc định của hệ thống.
- Đã thay bằng bản chính thức JetBrains Mono (repo JetBrains) và Fira Code v6.2 (release
  tonsky), kèm license OFL trong cùng thư mục.

### ✅ B-17. PAT trên emulator đã hết hạn / bị thu hồi — XONG 2026-10-25

> User cấp PAT mới; kiểm tra kết nối + sync + chuyển branch đều thành công.
> Mẹo: emulator vừa khởi động lại trên Windows có thể **mất DNS** (TCP tới IP vẫn được) →
> app báo "Không ra được tới remote". Bật/tắt chế độ máy bay là hết.

- **Hiện trạng (2026-10-24):** Sync báo `Incorrect credentials`; lần sync thành công cuối là 10/08.
  Đã thử cả bản **tắt isolate** → lỗi y hệt, nên không phải do B-11.
- **Việc cần làm (user):** tạo PAT mới (scope `repo` hoặc fine-grained Contents read/write) →
  Settings → Git Repository → Kiểm tra kết nối → Update Credentials. Sau đó mới bấm
  "Chuyển sang main" (B-14) và chạy thử sync đầu-cuối.

### ✅ B-18. Màn giải quyết conflict có thể làm commit dấu `<<<<<<<` lên remote — XONG 2026-10-25

- **Hiện trạng (kiểm chứng khi chuyển branch thật):** màn conflict ghi file nhưng **không gọi
  `markResolved`**, không làm mới danh sách note (note hiện tiêu đề lấy từ H1, mất tag), và chỉ
  mở file conflict **đầu tiên**. Sync sau đó stage mọi `*.md` → file còn dấu conflict bị commit.
  Thêm nữa: chọn "Keep Mine" cho cây giống HEAD nên commit bị bỏ qua, `MERGE_HEAD` nằm lại.
- **Đã sửa:** xem DECISIONS 2026-10-25 "Không bao giờ commit file còn dấu conflict".

### ✅ B-19. Nhãn LOCAL/REMOTE ở màn conflict sai nghĩa khi chuyển branch — XONG 2026-10-25

- Khi chuyển branch, "LOCAL (yours)" là bản của branch **đích** (`main`) còn bản ghi chú user
  vẫn dùng (`master`) lại nằm ở "REMOTE (theirs)". Dễ chọn nhầm.
- **Hướng:** truyền ngữ cảnh vào màn conflict (pull vs chuyển branch) và đặt nhãn theo tên
  branch: "Bản trên main" / "Bản trên master". Việc UI thuần, không cần chốt.

### ✅ B-20. Lịch sử sync hiện giờ UTC — XONG 2026-10-25

- Sheet Sync History ghi 13:06 khi đồng hồ máy là 20:06 (UTC+7). Cần `.toLocal()` khi hiển thị.

## Đợt rà soát 2026-10-25 (review code + soát độ hoàn thiện)

Hai agent rà toàn bộ thay đổi và toàn app; mọi mục dưới đây đã sửa, có test, đã thử trên emulator.

**Mất dữ liệu / hỏng repo**
- ✅ B-21. Sync tự động pull lúc editor mở → autosave ghi đè bản mới vừa kéo về. Editor so file trên đĩa trước khi lưu; sync tự động hoãn khi đang soạn (DECISIONS 2026-10-25).
- ✅ B-22. Pull fast-forward khi có file sửa dở lùi mất thay đổi từ remote; resolve conflict xong thì sync kẹt vĩnh viễn → đổi sang commit → pull → push (DECISIONS 2026-10-25).
- ✅ B-23. Màn conflict không markResolved, chỉ mở file đầu → file còn dấu conflict bị commit lên remote (B-18, DECISIONS 2026-10-25).
- ✅ B-24. Conflict modify/delete (file bị xóa) làm sync kẹt; chuyển branch chạy chồng với sync tự động (không chung khóa).
- ✅ B-25. Back hệ thống / app xuống nền làm mất chữ vừa gõ; note vừa xóa có thể bị autosave ghi lại.
- ✅ B-26. Xóa/đổi tên note lần hai cùng tham số bị bỏ qua (FutureProvider.family cache theo tham số).
- ✅ B-27. Mở lại note thấy nội dung cũ trong bộ nhớ (currentNoteProvider không tự hủy).
- ✅ B-28. libgit2 chờ mạng vô hạn → đặt timeout kết nối 15s, đọc/ghi 30s.
- ✅ B-29. Import: note trong thư mục con không hiện trong app nhưng vẫn bị commit → đưa về gốc; `.git` chặn mọi kiểu viết hoa.

**Độ bền / hoàn thiện**
- ✅ Onboarding: nút back bước Git từng crash; thêm Next/Skip; chặn bấm hai lần ở bước tạo note.
- ✅ Mọi thao tác (tạo/đổi tên/xóa note, collection, lưu cấu hình Git, lưu cài đặt, chia sẻ) báo lỗi thay vì im lặng hay quay mãi.
- ✅ Preview tô màu cú pháp code (flutter_highlight có sẵn mà chưa dùng), mở được link, theo font/cỡ chữ.
- ✅ Sửa tag của note; Toolbar Layout hiện tên dễ đọc; phiên bản app đọc từ gói cài.
- ✅ Bỏ chấm trạng thái từng note (luôn xám, không có dữ liệu); bỏ nút "Skip" khỏi Settings → Git.
- ✅ Thống nhất mặc định cỡ chữ 14 / tự lưu 3 giây; khoảng tự lưu đọc từ cài đặt.

**Hoàn thiện cuối đợt (2026-10-25)**
- ✅ Đa ngôn ngữ Việt + Anh (gen-l10n, 226 chuỗi), chọn ngôn ngữ trong Settings → Giao diện; ghi chú mẫu lúc onboarding theo ngôn ngữ.
- ✅ Bấm ô checklist trong preview; kéo thả sắp xếp collection.
- ✅ Kiểm thử trên emulator: back hệ thống lưu, preview tô màu + mở link, sửa tag, xóa, checklist, đổi ngôn ngữ, sync.

## Việc tiếp theo

Backlog không còn mục mở. Gợi ý cho đợt sau (chưa ai yêu cầu):
- Hiển thị note trong thư mục con của repo (hiện app chỉ liệt kê thư mục gốc).
- Sync nền khi app đóng (cần giải pháp chạy libgit2 ngoài tiến trình Flutter).
