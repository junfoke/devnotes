\# Implementation Plan



Để tránh lỗi context giới hạn, AI cần thực hiện code theo các Phase sau, hoàn thành Phase này mới sang Phase khác.



\- \*\*Phase 1: Project Setup \& UI Mockups.\*\* Khởi tạo project, cấu hình theme, GoRouter. Dựng tĩnh 3 màn hình (Explorer, Editor, Setup) với dummy data. Chưa gắn logic đọc file hay Git.

\- \*\*Phase 2: Local File System.\*\* Cài đặt repository để tạo folder làm việc, đọc/ghi file `.md`, parse YAML Frontmatter. Gắn Riverpod kết nối UI với File System.

\- \*\*Phase 3: Editor \& Markdown Rendering.\*\* Xử lý logic render Markdown, tích hợp syntax highlighter, xử lý auto-save và thanh công cụ gắn trên bàn phím.

\- \*\*Phase 4: Git Synchronization.\*\* Cài đặt secure storage lưu PAT. Tích hợp thư viện Git. Viết các hàm clone, pull, commit toàn bộ thay đổi và push. Gắn logic vào nút "Sync Now".

