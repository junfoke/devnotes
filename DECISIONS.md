# Decision Log — DevNotes

Nơi ghi **quyết định nghiệp vụ đã chốt**, không phải tài liệu mô tả code.

## Khi nào ghi vào đây

Chỉ ghi khi có **ngã rẽ thật** — chọn A thì sau này sửa sang B rất đau:

- Định dạng dữ liệu trên đĩa (tên file, frontmatter, cấu trúc workspace)
- Hành vi khi dữ liệu "lạ" hoặc hỏng (file thiếu meta, YAML sai, xung đột git)
- Luồng git sync (thứ tự pull/push, xử lý conflict, cái gì được commit)
- Bất cứ quyết định nào mà chọn sai = mất dữ liệu người dùng

**Không ghi:** thêm nút, đổi màu, sửa layout, đổi tên biến, thêm màn hình cho logic đã có.

## Cách ghi

Mỗi mục 4 dòng, không dài hơn:

```
## YYYY-MM-DD — <Chủ đề>
**Chốt:** <quyết định, đủ cụ thể để code theo>
**Vì:** <lý do — phần này quan trọng nhất, 6 tháng sau chỉ còn nó là hữu ích>
**Test:** <file test bảo vệ quyết định này>
```

Mục mới thêm **lên đầu** danh sách. Không sửa mục cũ — nếu đổi ý thì ghi mục mới và ghi `Thay cho: <ngày cũ>`.

---

## 2026-08-10 — File .md thiếu hoặc hỏng frontmatter

**Chốt:** Không bao giờ crash. Suy ra giá trị thay thế: `title` ← heading `# ` đầu tiên → tên file; `createdAt`/`updatedAt` ← thời gian sửa file trên đĩa; `tags` ← rỗng. YAML không parse được thì coi **toàn bộ** file là nội dung (không mất chữ nào). File không đọc được (I/O, không phải UTF-8) thì bỏ qua file đó, phần còn lại của danh sách vẫn hiện.

**Vì:** Workspace là một git repo dùng chung. File `.md` do người khác hoặc công cụ khác tạo — README, spec, note từ máy khác — phải mở và sửa được, không thì app vô dụng ngay khi sync về bất cứ thứ gì.

**Test:** `test/core/file_system/frontmatter_parser_ac_test.dart`, `test/core/file_system/note_file_repository_ac_test.dart`

## 2026-08-10 — Tên file sinh từ tiêu đề note

**Chốt:** Bỏ dấu tiếng Việt về ASCII rồi mới sanitize: `"Ghi chú họp thứ 2"` → `ghi-chu-hop-thu-2.md`, `đ`/`Đ` → `d`. Tiêu đề gốc **có dấu** giữ nguyên trong frontmatter `title` — tên file chỉ là định danh lưu trữ. Nếu sau khi sanitize không còn ký tự nào (tiêu đề toàn emoji/dấu câu) → dùng `untitled`, trùng thì thêm hậu tố đếm.

**Vì:** Tên file Unicode có rủi ro encoding NFC/NFD lệch nhau giữa Windows/macOS/Linux khi sync qua git — cùng một note có thể thành hai file trên hai máy. ASCII thì an toàn tuyệt đối. Còn `untitled` là để không bao giờ sinh file ẩn `.md` mà người dùng không thấy đâu.

**Test:** `test/core/file_system/note_file_repository_ac_test.dart`

## 2026-08-10 — Escape giá trị chuỗi trong YAML frontmatter

**Chốt:** Mọi chuỗi ghi vào frontmatter (`title`, từng phần tử `tags`) phải escape theo chuẩn YAML double-quoted: `\` → `\\` trước, rồi `"` → `\"`.

**Vì:** Tiêu đề chứa dấu nháy kép — rất thường gặp — sẽ làm hỏng cả file, và file hỏng thì mất toàn bộ note đó.

**Test:** `test/core/file_system/frontmatter_parser_ac_test.dart`

---

## Quyết định kế thừa (từ code, chưa từng được ghi lại tường minh)

Những mục dưới đây đã nằm trong code từ trước; ghi lại để biết **đang** theo rule nào, chứ không phải mới chốt hôm nay.

- **Sync theo thứ tự pull → commit → push.** Không bao giờ push trước khi pull. Xung đột làm dừng toàn bộ flow, user phải resolve rồi sync lại. Sync **không** atomic: pull xong mà push lỗi thì commit nằm lại local, không rollback.
- **Chỉ file `.md` được stage/commit.** File khác trong workspace bị git bỏ qua.
- **Giải quyết xung đột áp một chiến lược cho cả file** (Keep Mine / Keep Theirs / Keep Both), không chọn từng khối. Resolve xong không tự commit — user phải chạy Sync lại.
- **Import ZIP ghi đè note trùng tên.** ⚠️ Chưa từng được xác nhận là ý muốn — cần chốt lại trước khi làm màn hình Import (xem B-10 trong backlog).
- **Lọc theo collection dùng OR-logic:** note hiện nếu khớp **bất kỳ** tag nào trong `filterTags`. `filterTags` rỗng = khớp tất cả.
- **Tìm kiếm là prefix wildcard** trên FTS5 (`"query"*`), index gồm title + tags + content, tối đa 50 kết quả.
- **Chỉ hỗ trợ Git HTTPS + PAT**, không SSH. Credential lưu trong `FlutterSecureStorage`.
- **Autosave debounce 3 giây** sau lần gõ cuối; `updatedAt` cập nhật mỗi lần lưu, `createdAt` bất biến.
