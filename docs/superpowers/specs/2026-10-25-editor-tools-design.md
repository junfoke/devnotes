# Thiết kế: Bảng "Công cụ soạn thảo" trong editor

> Ngày: 2026-10-25 · Trạng thái: chờ user duyệt (đã qua review của người làm)
> Phạm vi: màn editor (`lib/features/editor/`) + Settings → Toolbar Layout.

## 1. Ý định — vì sao làm

User thấy editor "hơi đơn điệu": thanh công cụ hiện chỉ chèn cú pháp Markdown (H1…H3, B, I, S, link, ảnh, code…). Muốn đổi font, cỡ chữ phải thoát ra Settings. User muốn:

- chỉnh hiển thị (font, cỡ chữ…) **ngay trong lúc soạn**;
- có thêm **tiện ích hợp cho việc soạn thảo** ghi chú kỹ thuật trên điện thoại;
- một **nút nâng cao** trên thanh công cụ: bấm vào hiện đủ công cụ, không bấm thì gọn;
- **tự cấu hình** cái nào hiện ra, cái nào ẩn.

Thành công = mở một note, gõ, cần gì (đổi cỡ chữ, hoàn tác, thụt lề, chèn bảng, tìm chữ…) đều làm được ngay trong editor mà không phải rời màn hình.

## 2. Mục tiêu / không làm / không được xảy ra

**Mục tiêu**
- Nút `⋯` cố định ở **mép phải** thanh công cụ (không cuộn mất), mở **bottom sheet** "Công cụ soạn thảo" (user chọn kiểu B trong 3 bản phác thảo).
- Đủ **19 tiện ích** ở mục 4 (user: "đủ cả").
- Mỗi tiện ích có thể **ghim lên thanh công cụ** hoặc **ẩn khỏi bảng**; mặc định do người làm chọn (user giao).
- Settings → Toolbar Layout và bảng dùng **chung một cấu hình** — không lệch nhau.

**Không làm**
- Không làm editor WYSIWYG / rich text — văn bản vẫn là Markdown thô.
- Không lưu cách hiển thị riêng cho từng note (user đồng ý: font/cỡ chữ… áp dụng cho **mọi note**, như Settings hiện giờ).
- Không đổi định dạng file `.md` / frontmatter.

**Không được xảy ra (anti-goals)**
- Thao tác công cụ làm mất chữ hoặc không được autosave. Mọi công cụ sửa văn bản phải đi qua `TextEditingController` để listener autosave hiện có bắt được (xem DECISIONS: B-01, "Editor không ghi đè thay đổi từ bên ngoài").
- Bảng che mất chữ mà không đóng được bằng thao tác quen thuộc (vuốt xuống, chạm vùng tối, Back).
- Hai nơi cấu hình (bảng / Settings) hiện khác nhau.

## 3. Ràng buộc và hiện trạng

- Flutter + Riverpod; đa ngôn ngữ gen-l10n (`lib/l10n/app_vi.arb`, `app_en.arb`) — **mọi chuỗi mới có ở cả hai file**.
- Thanh công cụ: `lib/features/editor/presentation/widgets/markdown_toolbar.dart`; danh sách nút `ToolbarItem.allItems` (`lib/features/editor/domain/toolbar_item.dart`) — mỗi nút chỉ là "chèn chuỗi trước/sau vùng chọn".
- Cấu hình: `EditorPreferences` (`fontFamily`, `fontSize`, `toolbarItems` = danh sách id hiện + thứ tự, `autoSaveInterval`, sync…), lưu SharedPreferences qua `PreferencesRepository`; Settings có `FontSettingsSheet`, `ToolbarLayoutSheet` (`editor_settings_sheets.dart`).
- Theme: `themeProvider` (system/light/dark). Preview: `MarkdownPreview`.
- Font có sẵn: JetBrains Mono, Fira Code (bundled). "Font thường" = font mặc định của hệ thống.
- Quy trình repo: Decision-First TDD (`.claude/skills/decision-first-tdd`) — rule nào đụng dữ liệu phải có test.

## 4. Danh sách tiện ích (cả 19)

**Hiển thị** (lưu vào `EditorPreferences`, áp dụng mọi note, thấy ngay)
1. Font: JetBrains Mono / Fira Code / font hệ thống.
2. Cỡ chữ A− / A+ (giữ khoảng 12–24 như Settings hiện tại).
3. Giãn dòng: chặt / vừa / thoáng.
4. Tự xuống dòng bật/tắt (tắt → dòng dài cuộn ngang).
5. Chế độ tập trung: ẩn thanh tiêu đề editor; vẫn còn thanh công cụ và cách thoát ra.
6. Sáng / tối nhanh (đổi `themeProvider`).

**Sửa văn bản**
7. Hoàn tác / làm lại.
8. Thụt lề / lùi lề (dòng hiện tại hoặc các dòng trong vùng chọn).
9. Đưa dòng lên / xuống.
10. Nhân đôi dòng / xóa dòng.
11. Tìm & thay thế trong note đang mở (tìm tiếp/lùi, thay một, thay hết).

**Chèn nhanh**
12. Ngày giờ hiện tại.
13. Bảng có chọn số cột / hàng (thay cho bảng 2 cột cố định).
14. Khối code có chọn ngôn ngữ (để preview tô màu đúng).
15. Liên kết tới note khác (chọn từ danh sách note).
16. Mẫu ghi chú (biên bản họp, bug report, nhật ký… — có bản Việt và Anh).
17. Ký tự hay dùng khi viết code: `` ` `` `{ }` `[ ]` `|` `< >` `~` …

**Xem nhanh**
18. Mục lục: danh sách tiêu đề trong note, bấm để nhảy tới.
19. Số từ / ký tự / thời gian đọc.

## 5. Phần user đã quyết

- Kiểu mở: **bottom sheet** kéo lên từ dưới, bàn phím tạm ẩn khi mở, vuốt xuống để đóng.
- Lấy **đủ 19** tiện ích.
- Cài đặt hiển thị áp dụng **mọi note**.
- Mặc định ghim/ẩn: **giao cho người làm** (xem mục 6).

## 6. Quyết định của người làm (chưa được user xác nhận riêng — user giao)

- **Mặc định ghim lên thanh công cụ:** các nút Markdown hiện có + **Hoàn tác, Làm lại, Thụt lề, Lùi lề** (dùng liên tục, bàn phím điện thoại không có). Mọi thứ khác nằm trong bảng.
- **Cấu hình:** trong bảng có nút "Tùy chỉnh": mỗi tiện ích có hai công tắc *ghim lên thanh công cụ* và *ẩn khỏi bảng*. Settings → Toolbar Layout hiển thị đúng danh sách đó (cả nút Markdown lẫn tiện ích). Thứ tự trên thanh công cụ kéo thả được như hiện tại.
- **Bố cục bảng:** 4 nhóm theo mục 4; nhóm Hiển thị ở đầu, dạng chip/nút bấm đổi ngay; các nhóm còn lại dạng lưới nút.
- **Liên kết tới note khác** ghi dạng Markdown chuẩn tương đối: `[Tiêu đề](ten-file.md)` — đọc được trên GitHub. Trong preview, bấm link `.md` tương đối thì **mở note đó trong app** (không đưa ra trình duyệt). ⚠️ Đây là thay đổi về nội dung ghi xuống file → ghi vào `DECISIONS.md` khi làm.
- **Người dùng cũ nhận nút ghim mặc định mới:** ai đã lưu cấu hình thanh công cụ thì Hoàn tác / Làm lại / Thụt lề / Lùi lề được thêm vào **một lần** (cờ di trú trong SharedPreferences), sau đó tôn trọng mọi chỉnh sửa của họ.
- **Mô hình ghim/ẩn thống nhất:** mọi mục (nút Markdown cũ + 19 tiện ích) đều có hai thuộc tính: *ghim* (nằm trên thanh công cụ, có thứ tự) và *ẩn khỏi bảng*. Mục không ghim hiện trong bảng; nút Markdown không ghim nằm ở nhóm thứ 5 **"Định dạng"**. Mục vừa không ghim vừa ẩn thì chỉ còn tìm thấy trong Settings → Toolbar Layout (luôn liệt kê đủ mọi mục, nên không bao giờ mất hẳn). Id cũ giữ nguyên; nút `table` và `code_block` cũ mở luôn bộ chọn số cột/hàng (#13) và ngôn ngữ (#14) thay vì là hai tiện ích riêng.

## 6b. User quyết sau vòng review (2026-10-25)

- **Đổi tên note thì tự sửa link:** đổi tên note B (tên file đổi theo) thì app cập nhật mọi link `[…](b-cu.md)` trong các note khác sang tên file mới. Link không bao giờ gãy; các note chứa link sẽ có thay đổi ở lần sync sau (giống Obsidian). ⚠️ Rule đụng dữ liệu nhiều file → test trước, ghi `DECISIONS.md`: chỉ sửa đúng đích link (không đụng chữ khác, không đụng link trong khối code), việc sửa đi qua repository như mọi lần ghi, note đang lỗi đọc thì bỏ qua và báo.
- **Mẫu ghi chú:** bộ mẫu dựng sẵn trong code (không cho user tự tạo ở đợt này); chèn tại con trỏ.
- **Hoàn tác:** dùng lịch sử hoàn tác của `TextField` (`UndoHistoryController`), nên mọi thay đổi bằng code (toolbar, công cụ) cũng hoàn tác được.

## 7. Để người làm tự quyết

- Icon từng tiện ích, cách sắp trong lưới, chữ trên nút (có l10n).
- Cách hiện tìm & thay thế (thanh nổi trên editor hay trong sheet), miễn là vẫn thấy chữ đang tìm.
- Thời gian đọc tính theo bao nhiêu từ/phút.
- Có tách `toolbar_item.dart` thành mô hình "công cụ" chung (chèn chuỗi vs hành động) hay không — miễn cấu hình hiện có của user (`editor_toolbar_items` trong SharedPreferences) vẫn đọc được: id cũ giữ nguyên ý nghĩa, id mới thêm vào.
- Chia đợt triển khai (khuyến nghị: hiển thị + sửa văn bản trước, chèn + xem nhanh sau).
