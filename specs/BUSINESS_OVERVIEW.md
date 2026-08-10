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
| **Collection** | Nhóm ảo theo tag, lưu ở `{workspace}/collections.json`. Lọc **OR**: note hiện nếu khớp bất kỳ tag nào. `filterTags` rỗng = khớp tất cả. Chọn một collection tại một thời điểm. | `collections_repository.dart` |

## Editor

- Hai trang vuốt ngang: **soạn** (TextField thô) và **xem trước** (render Markdown). Thanh công cụ chỉ hiện ở trang soạn.
- **Autosave** debounce 3 giây sau lần gõ cuối; nhấn Back mà chưa lưu thì ép lưu trước khi thoát.
- Thanh công cụ Markdown chèn cú pháp quanh vùng chọn; mục dạng block tự thêm `\n` phía trước nếu đang ở giữa dòng. Danh sách nút hiện ra theo `editorPreferences.toolbarItems`.
- ⚠️ **Cú pháp chèn từ toolbar hiện KHÔNG được lưu** — xem B-01 trong [backlog](../docs/06_backlog_chuc_nang_chet.md).

Code: `editor_screen.dart`, `markdown_toolbar.dart`, `editor_providers.dart`

## Git Sync

Thứ tự nghiêm ngặt, không được đảo:

```
pull → (nếu có thay đổi) commit → push
```

- **Xung đột dừng toàn bộ flow.** File xung đột được đánh dấu `conflict`, app mở màn hình resolve. Phải resolve xong rồi sync lại.
- **Resolve**: chọn một chiến lược cho **cả file** (Keep Mine / Keep Theirs / Keep Both), không chọn từng khối. Resolve xong không tự commit.
- Chỉ file `.md` được stage. Commit rỗng (tree staged == HEAD tree) bị bỏ qua.
- **Không atomic**: pull xong mà push lỗi thì commit nằm lại local, không rollback.
- `initializeRepo` idempotent — thoát sớm nếu `.git/` đã tồn tại. Lần đầu: thử clone remote; clone lỗi thì `init` repo mới và giữ lại các file `.md` local.
- Credential: HTTPS + PAT trong `FlutterSecureStorage`, 4 khóa (`git_remote_url`, `git_username`, `git_pat`, `git_branch`). Không hỗ trợ SSH. Branch rỗng → `main`.

Code: `sync_service.dart`, `git2dart_client.dart`, `conflict_parser.dart`, `git_config_repository.dart`

## Settings

- **Theme**: light / dark / system (mặc định system), lưu `SharedPreferences` khóa `theme_preference`, giá trị lạ → fallback system.
- **Editor preferences**: fontSize (double), fontFamily (string, mặc định `JetBrainsMono`), toolbarItems (StringList). Lưu `SharedPreferences`, editor áp dụng khi mở note kế tiếp.
- **Export/Import ZIP**: chỉ file `.md`, giữ cấu trúc thư mục, đường dẫn chuẩn hóa dấu `/`.
- ⚠️ Nhiều mục Settings hiện **chưa có hành vi** — xem B-07 trong [backlog](../docs/06_backlog_chuc_nang_chet.md).

## Onboarding

Ba bước: Welcome (carousel 3 trang) → Git Setup (**có thể Skip**) → tạo note "Welcome to DevNotes" với nội dung mẫu. Xong thì đặt `onboarding_complete = true`, lần mở sau vào thẳng workspace.

Tooltip theo ngữ cảnh: mỗi màn hình có khóa riêng (`tooltip_{key}`), đã hiện một lần thì không hiện lại.

Code: `onboarding_*_screen.dart`, `tooltip_service.dart`

## Mô hình dữ liệu

Xem [`entities/entity-model.md`](entities/entity-model.md) — vẫn giữ nguyên, là tham chiếu tên gọi và cấu trúc entity (NoteFile, Collection, GitConfig, SyncState, SyncLogEntry, ConflictBlock, …).
