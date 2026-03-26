\# UI Screens \& Flows (Dựa trên thiết kế Dark Theme)



\*\*Design System chung:\*\*

\- Theme: Dark Mode mặc định. Màu nền tối (Dark Navy/Black), các điểm nhấn (nút bấm, icon đang active) dùng màu Tím (Purple).

\- Font chữ hiển thị văn bản thường: Roboto/San Francisco. 

\- Font chữ hiển thị code: Monospace (Fira Code, JetBrains Mono).



\*\*Các màn hình chính:\*\*

1\. \*\*Workspace Explorer (Home - `/`):\*\*

&#x20;  - AppBar: "DevNotes" ở bên trái. Bên phải có icon Git Status (hiển thị trạng thái nhánh) và nút "Sync Now" màu tím.

&#x20;  - Body: Danh sách các file `.md`. Mỗi item hiển thị tên file, các tags (dạng chip), và thời gian cập nhật.

&#x20;  - FAB: Nút dấu "+" màu tím góc dưới bên phải để tạo file mới.

2\. \*\*Markdown Editor (`/editor`):\*\*

&#x20;  - AppBar: Nút Back, Nút Toggle \[Edit | Preview].

&#x20;  - Chế độ Edit: TextField nhập liệu text thô. CÓ MỘT TOOLBAR gắn trên bàn phím để chèn nhanh cú pháp: H1, H2, Checklist, Code block.

&#x20;  - Chế độ Preview: Render Markdown và highlight code blocks.

3\. \*\*Git Setup (`/setup`):\*\*

&#x20;  - Form nhập: Git Remote URL, Username, và Personal Access Token (PAT) (ẩn dạng password).

&#x20;  - Nút "Connect Repository" màu tím to bản. Nút phụ "Skip for now" lưu cục bộ.

