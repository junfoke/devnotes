\# Data Structure (File-based)



Không sử dụng Database Schema. Dữ liệu được quản lý qua File System. Mỗi ghi chú là một file `.md`.



\*\*Cấu trúc chuẩn của một file `\[note\_title].md`:\*\*

Bao gồm YAML Frontmatter ở đầu file để lưu metadata, theo sau là nội dung Markdown.



```yaml

\---

title: "Tên ghi chú hiển thị"

tags: \["flutter", "idea", "todo"]

createdAt: "2023-10-27T10:00:00Z"

updatedAt: "2023-10-27T10:30:00Z"

\---

```



\# Nội dung ghi chú bắt đầu ở đây

\- Hỗ trợ \*\*Markdown\*\* tiêu chuẩn.

\- Các block code.



\*\*Thao tác IO yêu cầu:\*\*

App cần có khả năng parse (đọc) và serialize (ghi) đoạn YAML Frontmatter này mỗi khi load/save file.

