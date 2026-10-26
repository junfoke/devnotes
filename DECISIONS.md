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

## 2026-10-25 — Link giữa các note và tự sửa link khi đổi tên
**Chốt:** Link tới note khác ghi Markdown chuẩn tương đối `[Tiêu đề](ten-file.md)` (`[`/`]` trong tiêu đề escape `\`, khoảng trắng tên file `%20`); preview bấm link `.md` tương đối thì mở note trong app. Đổi tên note làm đổi tên file thì sau khi đổi tên xong, duyệt mọi note top-level (kể cả chính nó), chỉ đổi phần tên file trong đích `](…)` (giữ `./`, `#anchor`, title); không đụng link trong khối code (bảo thủ: fence thụt lề/trong blockquote, khối thụt 4 khoảng trắng/tab, code giữa dòng) và chữ thường; link kiểu tham chiếu `[x]: a.md` và link vào thư mục con không được sửa. Ghi bằng `rewriteBody`: giữ nguyên từng byte ngoài đích link — frontmatter (kể cả khóa lạ, `updatedAt`), file không/hỏng frontmatter, khoảng trắng, xuống dòng CRLF — ghi nguyên tử (file tạm rồi rename) và chỉ ghi khi nội dung đổi; note đọc/ghi lỗi thì bỏ qua và báo; đổi tên lỗi thì không đụng note nào; tên file không đổi thì không duyệt.
**Vì:** Link đọc được trên GitHub và không bao giờ gãy khi đổi tên (giống Obsidian); đây là thao tác ghi vào NHIỀU file của user nên chỉ được đổi đúng đích link, không ghi thừa (nhiễu sync), và một note hỏng không được chặn cả lượt. User chọn 2026-10-25 (spec mục 6, 6b).
**Test:** `test/features/editor/note_links_test.dart`, `test/features/workspace/rename_rewrites_links_test.dart`

## 2026-10-25 — Sync theo thứ tự commit → pull → push
**Chốt:** Mỗi lần sync: (0) xử lý file còn đánh dấu conflict (xem mục bên dưới) → (1) có thay đổi trên máy thì commit trước (đang dở merge thì là merge commit) → (2) pull; conflict thì dừng, chưa push → (3) push. Pull fast-forward thì checkout cây đích trước rồi mới dời branch; repo chưa có commit thì lấy nguyên branch từ remote. Thay cho: "Sync theo thứ tự pull → commit → push" (phần kế thừa).
**Vì:** Pull khi còn file sửa dở thì checkout fast-forward bị chặn giữa chừng, lần commit sau lùi mất toàn bộ thay đổi từ remote; và giải quyết conflict xong thì lần Sync kế tiếp luôn lỗi. Commit trước là cách git chuẩn: hai phía cùng sửa một note luôn thành conflict để user chọn. User chọn 2026-10-25.
**Test:** `test/core/git_client/sync_flow_ac_test.dart`, `test/features/git_sync/sync_service_ac_test.dart`

## 2026-10-25 — Editor không ghi đè thay đổi từ bên ngoài
**Chốt:** Sync tự động hoãn khi đang có editor mở, chạy ngay khi editor cuối cùng đóng. Trước mỗi lần lưu, editor so file trên đĩa với bản nó đọc/ghi lần cuối (nội dung, tiêu đề, tags): khác thì không ghi, hỏi "Tải bản mới" hoặc "Lưu bản của tôi thành note mới" (tiêu đề thêm " (bản sửa)"). Back hệ thống và app xuống nền cũng lưu; editor chưa tải xong note thì chưa cho gõ. Nội dung so sau khi cắt khoảng trắng đầu/cuối (file đọc lên đã bị cắt như vậy) — bổ sung 2026-10-26.
**Vì:** Sync kéo bản mới về trong lúc editor mở, autosave ghi nội dung cũ trên màn hình đè lên — bản sửa trên máy khác mất mà không có conflict nào. User chọn "hoãn sync + chặn ghi đè" 2026-10-25.
**Test:** `test/features/editor/editor_external_change_test.dart`

## 2026-10-25 — Import ZIP: note trong thư mục con đưa về thư mục gốc
**Chốt:** `notes/a.md` trong zip được ghi thành `a.md` ở gốc workspace; trùng tên thì theo luật bản sao sẵn có. `.git` bị chặn không phân biệt hoa thường. Bổ sung cho mục 2026-10-24 "Import ZIP: trùng tên thì tạo bản sao".
**Vì:** App chỉ liệt kê note ở thư mục gốc — note nhập vào thư mục con sẽ không hiện trong app nhưng vẫn bị commit và đẩy lên. User chọn 2026-10-25.
**Test:** `test/features/settings/import_zip_ac_test.dart`

## 2026-10-25 — Không bao giờ commit file còn dấu conflict
**Chốt:** Đầu mỗi lần sync, duyệt các file git còn đánh dấu conflict: file đã hết `<<<<<<<` (giải quyết qua màn hình hoặc sửa tay) → đánh dấu đã giải quyết; còn dù một file có dấu → dừng, không pull/commit/push, mở màn giải quyết. Commit khi đang dở merge luôn là merge commit (thêm `MERGE_HEAD` làm cha) rồi dọn trạng thái merge, kể cả khi cây file giống hệt HEAD. Màn conflict giải quyết xong một file thì tự sang file kế tiếp.
**Vì:** `commitAll` stage mọi `*.md` — trước đây màn conflict chỉ mở file đầu tiên và không báo git, nên Sync có thể commit file còn nguyên dấu conflict lên remote; còn `MERGE_HEAD` sót lại làm hỏng những lần pull sau. Phát hiện khi kiểm thử chuyển branch thật trên emulator.
**Test:** `test/features/git_sync/sync_service_ac_test.dart`, `test/core/git_client/git2dart_client_test.dart`

## 2026-10-24 — Sync tự động
**Chốt:** 3 chế độ: Thủ công (mặc định) / Khi mở app (mở app + quay lại app, cách nhau ≥ 5 phút) / Định kỳ 15–30–60 phút. Chỉ sync khi app đang mở, không sync nền. Mỗi lúc một lần sync (nút Sync và tự động dùng chung khóa). Sync tự động bỏ qua khi repo còn conflict, và không bao giờ tự mở màn hình — lỗi/conflict chỉ hiện ở chấm trạng thái và lịch sử.
**Vì:** libgit2 chạy qua FFI không sống được trong tiến trình nền Android, sync nền còn tốn pin. Hai lần sync chồng nhau trên cùng repo có thể làm hỏng index. App tự nhảy sang màn conflict giữa lúc user đang gõ là mất ngữ cảnh. User chọn "xem hướng nào tốt nhất".
**Test:** `test/features/git_sync/auto_sync_ac_test.dart`

## 2026-10-24 — Sync luôn push sau khi pull thành công
**Chốt:** Thứ tự vẫn là pull → (có thay đổi thì) commit → push, nhưng push chạy **cả khi không có thay đổi mới**. Repo chưa có commit nào thì push bỏ qua. Thay cho dòng "không atomic" trong phần kế thừa ở chỗ: commit kẹt lại sẽ được đẩy ở lần sync kế tiếp.
**Vì:** Trước đây chỉ push khi có thay đổi mới — một lần push lỗi mạng làm commit nằm kẹt trên máy cho tới khi user sửa thêm note khác, trong khi chấm trạng thái lại báo xanh.
**Test:** `test/features/git_sync/sync_service_ac_test.dart`

## 2026-10-24 — Branch local lệch branch cấu hình (B-14)
**Chốt:** Màn Git Setup hiện cảnh báo khi branch đang checkout khác branch cấu hình, kèm nút `Chuyển sang "<branch>"` (hỏi xác nhận). Chuyển = commit thay đổi đang dở → fetch → lấy branch đích (local sẵn có → `origin/<branch>` → tạo từ HEAD) → checkout → **merge branch cũ vào** → push. Trùng file khác nội dung thì dừng ở conflict và mở màn giải quyết. Branch cũ giữ nguyên, không xóa.
**Vì:** Checkout thẳng sẽ làm toàn bộ note của branch cũ biến mất khỏi app. Không tự chuyển khi Sync vì user phải biết repo vừa bị đổi branch. User chọn "c rồi chuyển a" + merge + nút trong cảnh báo.
**Test:** `test/core/git_client/switch_branch_ac_test.dart`

## 2026-10-24 — Xóa collection
**Chốt:** Xóa collection chỉ bỏ nhóm khỏi `collections.json`, không đụng file `.md` nào. Đang lọc theo collection vừa xóa thì quay về All Notes. Sửa collection giữ nguyên `id` và vị trí.
**Vì:** Collection là bộ lọc ảo theo tag; xóa note theo nó là mất dữ liệu ngoài ý muốn.
**Test:** `test/features/workspace/collection_edit_delete_ac_test.dart`

## 2026-10-24 — Import ZIP: trùng tên thì tạo bản sao
**Chốt:** Giải nén toàn bộ zip vào bộ nhớ trước — zip hỏng thì báo lỗi, không ghi file nào. Trùng tên + giống hệt từng byte (với note gốc hoặc bản sao `-N` đã có) → bỏ qua. Trùng tên + khác nội dung → ghi `ten-1.md`, `ten-2.md`… giữ nguyên nội dung file. Mục có `../`, đường dẫn tuyệt đối hoặc nằm trong `.git` → từ chối. Chỉ nhập `.md`. Xong báo tóm tắt: thêm mới / bỏ qua / bản sao / từ chối. Thay cho: "Import ZIP ghi đè note trùng tên" trong phần kế thừa.
**Vì:** Ghi đè là mất note không cách nào lấy lại. Bỏ qua bản giống hệt để nhập lại cùng một zip không đẻ hàng loạt bản sao. Chặn `../` vì zip từ ngoài có thể ghi đè dữ liệu app (zip slip, B-16).
**Test:** `test/features/settings/import_zip_ac_test.dart`

## 2026-10-24 — Xóa note từ editor không được để autosave ghi lại
**Chốt:** Xóa từ menu ⋮ trong editor: hủy timer autosave, đánh dấu đã xóa để mọi lần lưu sau bị bỏ qua, chờ lần ghi đang dở xong rồi mới xóa file.
**Vì:** Timer debounce 3 giây chạy sau khi xóa sẽ ghi lại file — note "sống lại" và bị sync lên remote.
**Test:** `test/features/editor/editor_more_menu_test.dart`

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

- ~~**Sync theo thứ tự pull → commit → push.**~~ Đã thay bằng mục 2026-10-25 "commit → pull → push". Không bao giờ push trước khi pull. Xung đột làm dừng toàn bộ flow, user phải resolve rồi sync lại. Sync **không** atomic: pull xong mà push lỗi thì commit nằm lại local, không rollback.
- **Chỉ file `.md` được stage/commit.** File khác trong workspace bị git bỏ qua.
- **Giải quyết xung đột áp một chiến lược cho cả file** (Keep Mine / Keep Theirs / Keep Both), không chọn từng khối. Resolve xong không tự commit — user phải chạy Sync lại.
- ~~**Import ZIP ghi đè note trùng tên.**~~ Đã thay bằng mục 2026-10-24 "Import ZIP: trùng tên thì tạo bản sao".
- **Lọc theo collection dùng OR-logic:** note hiện nếu khớp **bất kỳ** tag nào trong `filterTags`. `filterTags` rỗng = khớp tất cả.
- **Tìm kiếm là prefix wildcard** trên FTS5 (`"query"*`), index gồm title + tags + content, tối đa 50 kết quả.
- **Chỉ hỗ trợ Git HTTPS + PAT**, không SSH. Credential lưu trong `FlutterSecureStorage`.
- **Autosave debounce 3 giây** sau lần gõ cuối; `updatedAt` cập nhật mỗi lần lưu, `createdAt` bất biến.
