# Entity Model — DevNotes (Ubiquitous Language)

> Tài liệu này dịch ngược (reverse-engineer) từ code hiện tại. Mô tả các **danh từ nghiệp vụ** (Entity) và ngôn ngữ thống nhất dùng xuyên suốt Spec.

---

## 1. NoteFile (Ghi chú)
Đơn vị nội dung chính của ứng dụng. Mỗi note là một file Markdown trên ổ đĩa, định danh bằng đường dẫn file.

| Thuộc tính | Kiểu | Mô tả |
|-----------|------|-------|
| `filePath` | String | Đường dẫn tuyệt đối tới file `.md`. **Khóa định danh** (equality chỉ dựa trên trường này). |
| `title` | String | Tiêu đề hiển thị (lấy từ frontmatter). |
| `tags` | List\<String> | Nhãn phân loại, lưu trong YAML frontmatter. |
| `createdAt` | DateTime (UTC) | Thời điểm tạo. Bất biến sau khi tạo. |
| `updatedAt` | DateTime (UTC) | Thời điểm sửa gần nhất. Cập nhật mỗi lần lưu/đổi tên. |
| `content` | String | Nội dung Markdown (phần thân, không gồm frontmatter). |
| `syncStatus` | SyncStatus | Trạng thái đồng bộ git (xem mục 9). |
| `conflictRef` | String? | Tham chiếu phiên bản xung đột khi merge (nullable). |
| `collectionId` | String? | Khóa ngoại tới Collection sở hữu. `null` = chưa phân loại. |

**Quy tắc lưu trữ:** File theo định dạng YAML frontmatter (`--- ... ---`) + thân Markdown. Nội dung được trim. Nếu file thiếu frontmatter → mặc định title/tags rỗng, `createdAt`/`updatedAt` = thời điểm hiện tại, toàn bộ file là content.

**Quan hệ:** thuộc 0..1 Collection (qua `collectionId`).

---

## 2. Collection (Bộ sưu tập)
Nhóm logic gom các note theo nhãn. Lưu trong `collections.json` tại workspace.

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `id` | String (UUID v4) | — | Định danh duy nhất. |
| `name` | String | — | Tên hiển thị trên sidebar. |
| `icon` | IconData | `Icons.folder` | Biểu tượng. |
| `color` | Color (ARGB32) | `Colors.blue` | Màu nhấn. |
| `filterTags` | List\<String> | `[]` | Tập nhãn dùng để lọc note vào collection. |
| `sortOrder` | int | `0` | Thứ tự hiển thị (nhỏ hơn = lên trên). |

**Quy tắc lọc (OR-logic):** một note thuộc collection nếu note có **bất kỳ** tag nào nằm trong `filterTags`. Nếu `filterTags` rỗng → khớp tất cả note.

---

## 3. ParsedNote (DTO nội bộ)
Kết quả trung gian khi parse frontmatter — cầu nối giữa file thô và `NoteFile`.
Trường: `title`, `tags`, `createdAt`, `updatedAt`, `content`.

Cấu trúc frontmatter YAML:
```yaml
---
title: "Tiêu đề"
tags: ["tag1", "tag2"]
createdAt: "2026-01-15T10:30:00.000Z"
updatedAt: "2026-01-15T12:45:00.000Z"
---
<nội dung markdown>
```
Regex parse: `^---\s*\n([\s\S]*?)\n---\s*\n?`. `createdAt`/`updatedAt` ISO8601 bắt buộc; `tags` mặc định rỗng nếu vắng.

---

## 4. FileMetadata (Bảng SQLite `file_metadata`)
Lưu trạng thái đồng bộ tách khỏi file để truy vấn nhanh.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `file_path` | TEXT PK | Tham chiếu `NoteFile.filePath`. |
| `sync_status` | TEXT (NOT NULL, default `'synced'`) | Tên enum SyncStatus. |
| `conflict_ref` | TEXT? | Tham chiếu phiên bản xung đột. |

**Quy tắc:** upsert theo `ON CONFLICT(file_path) DO UPDATE`. Khi phát hiện xung đột → `sync_status='conflict'` + ghi `conflict_ref`. Khi xóa xung đột → reset về `'synced'`, `conflict_ref=NULL`. `getSyncStatus` mặc định trả `synced` nếu không có bản ghi.

---

## 5. SyncLogEntry (Bảng SQLite `sync_log`)
Nhật ký audit cho mọi thao tác git.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `id` | INTEGER PK AUTOINCREMENT | — |
| `timestamp` | DateTime (UTC) | Thời điểm thao tác. |
| `action` | SyncAction | `push` \| `pull` \| `commit` \| `fetch`. |
| `filesChanged` | int | Số file thay đổi. |
| `success` | bool (0/1) | Thành công hay không. |
| `errorMessage` | String? | Mô tả lỗi nếu thất bại. |

`getSyncLog(limit=50)` trả về sắp xếp `id DESC` (mới nhất trước).

---

## 6. SearchResult & SearchIndex (FTS5)
Bảng ảo `notes_fts USING fts5(title, tags, content, file_path UNINDEXED)`.

**SearchResult:** `filePath`, `title`, `snippet` (32 ký tự ngữ cảnh, highlight `<b></b>`).

**Quy tắc truy vấn:** prefix wildcard `"<query>"*` (escape dấu `"` thành `""`); order by rank; giới hạn 50 kết quả; bắt `SqliteException` → trả `[]`. Index **rebuild toàn bộ** mỗi khi danh sách note thay đổi (atomic BEGIN/COMMIT/ROLLBACK).

---

## 7. GitConfig (Cấu hình Git)
Lưu an toàn qua `FlutterSecureStorage`.

| Thuộc tính | Kiểu | Mặc định | Khóa lưu trữ | Bắt buộc |
|-----------|------|----------|--------------|----------|
| `remoteUrl` | String | — | `git_remote_url` | ✓ |
| `username` | String | — | `git_username` | ✓ |
| `pat` | String | — | `git_pat` | ✓ (nhạy cảm, hiển thị che) |
| `branch` | String | `"main"` | `git_branch` | tùy chọn |

Chỉ hỗ trợ xác thực **HTTPS qua PAT** (không SSH). Credentials truyền theo từng thao tác (callback `UserPass`), **không** ghi vào `.git/config`.

---

## 8. SyncState (Trạng thái đồng bộ — in-memory)
| Thuộc tính | Kiểu | Mặc định |
|-----------|------|----------|
| `branchName` | String | — |
| `status` | SyncStatus | `synced` |
| `lastSyncAt` | DateTime? | `null` |
| `history` | List\<SyncLogEntry> | `[]` |

---

## 9. SyncStatus (Enum)
`idle` | `syncing` | `success` | `error` | `pending` | `synced` | `conflict`.

## 10. SyncAction (Enum)
`push` | `pull` | `commit` | `fetch`.

---

## 11. ConflictBlock / Resolution (Mô hình xung đột)
**ConflictBlock:** `type` (BlockType: `clean` | `conflict`), `content`, `localContent?`, `remoteContent?`.

Regex phát hiện: `<{7} .*\n([\s\S]*?)={7}\n([\s\S]*?)>{7} .*` (chuẩn Git conflict marker).

**Resolution (Enum):** `keepMine` (giữ local) | `keepTheirs` (giữ remote) | `keepBoth` (nối `local\nremote`). Áp dụng **một chiến lược cho toàn bộ file**.

---

## 12. EditorPreferences (Tùy chỉnh trình soạn thảo)
Lưu qua `SharedPreferences`.

| Thuộc tính | Kiểu | Mặc định | Khóa |
|-----------|------|----------|------|
| `fontSize` | double | 16.0 (object) / 14.0 (stored) | `editor_font_size` |
| `fontFamily` | String | `'JetBrainsMono'` | `editor_font_family` |
| `autoSaveInterval` | Duration | 5s (object) / 3s (stored) | `editor_autosave_seconds` |
| `toolbarItems` | List\<String> | 16 mục mặc định | `editor_toolbar_items` |
| `syncFrequency` | SyncFrequency | `manual` | `sync_frequency` |
| `periodicInterval` | Duration | 30 phút | `sync_periodic_minutes` |

**SyncFrequency (Enum):** `manual` | `periodic`.

---

## 13. ToolbarItem (Nút thanh công cụ Markdown)
| Thuộc tính | Kiểu | Mặc định |
|-----------|------|----------|
| `id` | String | — (vd `h1`, `bold`, `code_block`) |
| `label` | String | — |
| `icon` | IconData? | null |
| `insertBefore` | String | — (cú pháp prefix) |
| `insertAfter` | String | `''` (cú pháp suffix) |
| `isBlock` | bool | `false` (true cho heading/code block/list/quote/table/hr) |

16 mục dựng sẵn: h1, h2, h3, bold, italic, strikethrough, link, image, code_inline, code_block, checklist, list_unordered, list_ordered, quote, table, hr. Mục `isBlock` tự thêm `\n` prefix nếu không ở đầu dòng.

---

## 14. ThemePreference (Enum) & SaveStatus (Enum)
- **ThemePreference:** `dark` | `light` | `system` (mặc định `system`, lưu khóa `theme_preference`). `system` phân giải theo brightness thiết bị.
- **SaveStatus:** `saved` | `saving` | `unsaved` (in-memory, hiển thị qua chấm trạng thái trên AppBar).

---

## 15. OnboardingState & TooltipState
- **Onboarding:** cờ `onboarding_complete: bool` (`SharedPreferences`). Flow theo route: `/onboarding` → `/onboarding/git` → `/onboarding/first-note` → `/`.
- **Tooltip:** khóa `tooltip_{key}: bool`. `shouldShow` = true nếu vắng/false; `markShown` set true (hiển thị một lần).
