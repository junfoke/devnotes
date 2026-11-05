# specs/ — Tham chiếu nghiệp vụ

Hai file, cả hai đều là **tham chiếu để đọc**, không phải tài liệu bắt buộc cập nhật trước khi code.

- [`BUSINESS_OVERVIEW.md`](BUSINESS_OVERVIEW.md) — app làm gì, luật nghiệp vụ chính nằm ở file code nào. Đọc 5 phút.
- [`entities/entity-model.md`](entities/entity-model.md) — mô hình dữ liệu và tên gọi thống nhất (NoteFile, Collection, GitConfig, SyncState, …).

## Quyết định nghiệp vụ nằm ở đâu

👉 [`../DECISIONS.md`](../DECISIONS.md) — chỉ ghi những quyết định có ngã rẽ thật (định dạng dữ liệu, xử lý dữ liệu hỏng, luồng git sync). Đây là file **cần cập nhật** khi chốt rule mới.

Hành vi chi tiết thì đọc tên test trong `test/` — test là đặc tả chính xác nhất vì nó không thể lệch khỏi code.

## Lịch sử

Trước đây thư mục này có 19 file `UC-XXX.md` viết ngược từ code theo quy trình Spec-Driven Development đầy đủ. Đã nén lại thành `BUSINESS_OVERVIEW.md` vào **2026-08-10** vì với dự án cá nhân, tầng tài liệu song song với code tốn công bảo trì hơn giá trị nó mang lại — phần thực sự có ích (chốt rule trước khi code, test bảo vệ rule) được giữ lại dưới dạng `DECISIONS.md` + TDD.
