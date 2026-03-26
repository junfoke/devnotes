\# Architecture \& Tech Stack



\- \*\*Framework:\*\* Flutter (phiên bản mới nhất, yêu cầu Strict Null-Safety).

\- \*\*Architecture Pattern:\*\* Feature-first Architecture (Tách biệt UI, Controller/State, Repository).

\- \*\*State Management:\*\* `flutter\_riverpod` (Sử dụng annotations/Code generation nếu cần thiết).

\- \*\*Routing:\*\* `go\_router`.

\- \*\*Core Packages:\*\*

&#x20; - `path\_provider` \& `dart:io`: Thao tác đọc/ghi file `.md` cục bộ.

&#x20; - `libgit2dart` (hoặc package git client tương đương hoạt động tốt trên mobile): Xử lý các lệnh Git clone, pull, commit, push.

&#x20; - `flutter\_markdown` \& `flutter\_highlight`: Render giao diện Markdown và Code Syntax.

&#x20; - `flutter\_secure\_storage`: Lưu trữ an toàn Git Personal Access Token (PAT).

