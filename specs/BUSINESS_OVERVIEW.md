# DevNotes — Tổng quan nghiệp vụ

> Bản nén từ 19 file use-case (viết ngược từ code, 2026-08). Mục đích: đọc 5 phút là nắm được app **làm gì** và luật nghiệp vụ nằm ở đâu trong code.
>
> Đây là **bản đồ**, không phải hợp đồng. Quyết định nghiệp vụ đã chốt nằm ở [`DECISIONS.md`](../DECISIONS.md); hành vi chi tiết nằm ở tên các test trong `test/`.

## App là gì

Ứng dụng ghi chú Markdown local-first cho developer. Note là **file `.md` thật** trên máy, có YAML frontmatter (`title`, `tags`, `createdAt`, `updatedAt`). Toàn bộ workspace là một **git repo** đồng bộ hai chiều với remote riêng của người dùng qua HTTPS + PAT. Không có server của bên nào cả.

## Workspace — quản lý ghi chú

| Việc | Luật chính | Code |
|------|-----------|------|
| **Tạo note** | Tiêu đề bắt buộc. Tên file sinh từ tiêu đề (xem DECISIONS). Trùng tên → hậu tố `-1`, `-2`. | `note_file_repository.dart`, `create_note_dialog.dart` |
| **Đổi tên** | Ghi file mới rồi xóa file cũ (không transaction — xóa lỗi thì còn file mồ côi). Giữ `createdAt`, `tags`, `content`. | `note_file_repository.dart` |
| **Xóa** | Bắt buộc xác nhận. Chỉ xóa file `.md`; bản ghi metadata trong SQLite **không** cascade. | `workspace_screen.dart` |
| **Liệt kê** | Chỉ file `.md`, sắp theo `updatedAt` giảm dần. File thiếu frontmatter vẫn đọc được (xem DECISIONS). | `note_file_repository.dart` |
| **Tìm kiếm** | Debounce 300ms, FTS5 prefix wildcard, index gồm title+tags+content, tối đa 50 kết quả. Index rebuild toàn bộ mỗi khi danh sách note đổi. | `search_engine.dart`, `search_providers.dart` |
| **Collection** | Nhóm ảo theo tag, lưu ở `{workspace}/collections.json`. Lọc **OR**: note hiện nếu khớp bất kỳ tag nào. `filterTags` rỗng = khớp tất cả. Chọn một collection tại một thời điểm. Nhấn giữ chip → sửa/xóa; xóa chỉ bỏ nhóm, không đụng note. Thứ tự theo `sortOrder`, kéo thả trong Manage Collections. | `collections_repository.dart` |

## Editor

- Hai trang vuốt ngang: **soạn** (TextField thô) và **xem trước** (render Markdown). Thanh công cụ chỉ hiện ở trang soạn.
- **Autosave** debounce 3 giây sau lần gõ cuối; nhấn Back mà chưa lưu thì ép lưu trước khi thoát.
- Thanh công cụ Markdown chèn cú pháp quanh vùng chọn; mục dạng block tự thêm `\n` phía trước nếu đang ở giữa dòng. Nút hiện ra **theo đúng thứ tự** của `editorPreferences.toolbarItems` (sắp trong Settings → Toolbar Layout).
- **Bảng công cụ `⋯`** (nút cố định ở mép phải thanh công cụ, mở bottom sheet, ẩn bàn phím): 38 công cụ chia 5 nhóm — Hiển thị (font, cỡ chữ, giãn dòng, tự xuống dòng, chế độ tập trung, sáng/tối; đổi ngay, bảng giữ mở), Chỉnh sửa (hoàn tác/làm lại, thụt/lùi lề, tìm & thay…), Chèn (ngày giờ, ký tự, mẫu ghi chú, link tới note khác), Xem (mục lục, thống kê từ/ký tự) và Định dạng (nút Markdown không ghim, gồm cả bảng và khối code). Cài đặt hiển thị áp dụng cho **mọi note**.
- **Ghim / ẩn:** mỗi công cụ có hai công tắc — *Ghim* (nằm trên thanh công cụ, có thứ tự) và *Hiện trong bảng*. Mặc định ghim các nút Markdown cũ + Hoàn tác, Làm lại, Thụt lề, Lùi lề. Người dùng cũ được thêm 4 nút chỉnh sửa lên đầu **một lần** rồi tôn trọng mọi chỉnh sửa. Cấu hình lưu trong `EditorPreferences` (`toolbarItems` = ghim có thứ tự, `hiddenTools` = ẩn khỏi bảng); chỉnh được ngay trong bảng (nút Tùy chỉnh) hoặc ở Settings → Toolbar Layout — hai nơi dùng chung một cấu hình nên đổi bên này thấy ngay bên kia. Mục vừa không ghim vừa ẩn vẫn được liệt kê ở Settings để bật lại.
- **Tìm & thay thế** trong note, **mục lục** (nhảy tới tiêu đề) và **thống kê** (số từ, ký tự, thời gian đọc) mở từ bảng công cụ.
- **Link giữa các note:** chèn `[Tiêu đề](ten-file.md)`; bấm trong preview thì mở note đích ngay trong app. Khi **đổi tên** note, mọi link trỏ tới nó trong các note khác được tự sửa (ghi nguyên văn từng byte, bỏ qua khối code). Đây là ngoại lệ duy nhất cho quy tắc "không đổi định dạng file `.md`" (ghi `DECISIONS.md`).
- **Mẫu ghi chú** chèn cấu trúc dựng sẵn vào vị trí con trỏ.
- Preview tô màu cú pháp khối code, mở được link, bấm được ô checklist (đổi đúng dòng trong văn bản), theo font/cỡ chữ đã chọn.
- Menu ⋮: Chia sẻ / Sửa tag / Thông tin / Xóa.
- Autosave bắt **mọi** thay đổi nội dung (cả gõ phím lẫn chèn từ toolbar); chỉ dời con trỏ thì không tính.
- **Lưu lỗi**: báo snackbar, trạng thái về `unsaved`; bấm Back khi lưu lỗi thì ở lại editor để không mất nội dung.

Code: `editor_screen.dart`, `markdown_toolbar.dart`, `editor_providers.dart`

## Git Sync

Thứ tự nghiêm ngặt, không được đảo:

```
(nếu có thay đổi) commit → pull → push
```

- **Xung đột dừng toàn bộ flow.** File xung đột được đánh dấu `conflict`, app mở màn hình resolve. Phải resolve xong rồi sync lại.
- **Resolve**: chọn một chiến lược cho **cả file** (Keep Mine / Keep Theirs / Keep Both), không chọn từng khối. Resolve xong không tự commit.
- Chỉ file `.md` được stage. Commit rỗng (tree staged == HEAD tree) bị bỏ qua.
- **Không atomic**: pull xong mà push lỗi thì commit nằm lại local, không rollback — nhưng sync **luôn push**, nên lần sync kế tiếp sẽ đẩy nó lên (DECISIONS 2026-10-24).
- **Một lần sync tại một thời điểm** (`SyncRunner`), dùng chung cho nút Sync và sync tự động. Mọi thao tác git chạy trong isolate phụ (`Git2dartClient` → `Git2dartOps`).
- **Sync tự động** (Settings → Sync Frequency): Thủ công / Khi mở app / Định kỳ, chỉ khi app đang mở; không bao giờ tự mở màn hình.
- **Branch lệch cấu hình**: Git Setup cảnh báo + nút chuyển; chuyển = merge branch cũ vào branch đích, giữ branch cũ.
- `initializeRepo` idempotent — thoát sớm nếu `.git/` đã tồn tại. Lần đầu: thử clone remote; clone lỗi thì `init` repo mới và giữ lại các file `.md` local.
- Credential: HTTPS + PAT trong `FlutterSecureStorage`, 4 khóa (`git_remote_url`, `git_username`, `git_pat`, `git_branch`). Không hỗ trợ SSH. Branch rỗng → `main`.

Code: `sync_service.dart`, `sync_runner.dart`, `sync_controller.dart`, `auto_sync_policy.dart`, `git2dart_client.dart`, `conflict_parser.dart`, `git_config_repository.dart`

## Settings

- **Theme**: light / dark / system (mặc định system), lưu `SharedPreferences` khóa `theme_preference`, giá trị lạ → fallback system.
- **Editor preferences**: fontSize (double), fontFamily (string, mặc định `JetBrainsMono`), toolbarItems (StringList, nút đang ghim theo thứ tự), hiddenTools (StringList, công cụ ẩn khỏi bảng ⋯), lineHeight, wordWrap, focusMode. Lưu `SharedPreferences`; đổi ở Settings hay ở bảng `⋯` thì editor đang mở áp dụng ngay.
- **Export ZIP**: chỉ file `.md`, giữ cấu trúc thư mục, đường dẫn chuẩn hóa dấu `/`; xong mở share sheet.
- **Import ZIP**: không bao giờ ghi đè — trùng tên giống hệt thì bỏ qua, khác nội dung thì tạo `ten-1.md`; chặn `../` (DECISIONS 2026-10-24).
- Font & Size, Toolbar Layout (liệt kê mọi công cụ theo nhóm, mục ghim ở trên cùng và kéo thả được), Sync Frequency, Rebuild Search Index, Manage Collections đều đã có hành vi.

## Onboarding

Ba bước: Welcome (carousel 3 trang) → Git Setup (**có thể Skip**) → tạo note "Welcome to DevNotes" với nội dung mẫu. Xong thì đặt `onboarding_complete = true`, lần mở sau vào thẳng workspace.

Tooltip theo ngữ cảnh: mỗi màn hình có khóa riêng (`tooltip_{key}`), đã hiện một lần thì không hiện lại.

Code: `onboarding_*_screen.dart`, `tooltip_service.dart`

## Ngôn ngữ

Giao diện Việt + Anh (`lib/l10n/*.arb`, gen-l10n). Settings → Giao diện → Ngôn ngữ: Theo hệ thống / Tiếng Việt / English, lưu khóa `app_locale`. Theo hệ thống mà máy không dùng vi/en thì dùng tiếng Anh. Lịch sử sync và commit message giữ dạng kỹ thuật, không dịch.

## Mô hình dữ liệu

Xem [`entities/entity-model.md`](entities/entity-model.md) — vẫn giữ nguyên, là tham chiếu tên gọi và cấu trúc entity (NoteFile, Collection, GitConfig, SyncState, SyncLogEntry, ConflictBlock, …).
