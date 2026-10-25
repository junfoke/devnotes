/// Ghi chú mẫu tạo ở bước cuối onboarding, theo ngôn ngữ giao diện lúc đó.
///
/// Là nội dung note (ghi xuống file `.md`), không phải chữ giao diện, nên nằm
/// ở đây thay vì trong file ARB. Tag giữ nguyên `getting-started`.
class SampleNote {
  const SampleNote({required this.title, required this.content});

  final String title;
  final String content;

  static const tags = ['getting-started'];

  /// Bản tiếng Việt cho `vi`, mọi ngôn ngữ khác dùng bản tiếng Anh.
  static SampleNote forLanguage(String languageCode) =>
      languageCode == 'vi' ? vi : en;

  static const en = SampleNote(
    title: 'Welcome to DevNotes',
    content: '''# Welcome to DevNotes!

This is your first note. Here's a quick Markdown guide:

## Text Formatting
- **Bold** text with `**double asterisks**`
- _Italic_ text with `_underscores_`
- ~~Strikethrough~~ with `~~tildes~~`

## Code
Inline code with backticks: `print('Hello')`

Code blocks with triple backticks:
```dart
void main() {
  print('Hello, DevNotes!');
}
```

## Lists
- Unordered items with `-`
1. Ordered items with numbers

## Task Lists
- [x] Install DevNotes
- [ ] Write your first note
- [ ] Set up Git sync

Happy note-taking!
''',
  );

  static const vi = SampleNote(
    title: 'Chào mừng đến với DevNotes',
    content: '''# Chào mừng đến với DevNotes!

Đây là ghi chú đầu tiên của bạn. Dưới đây là hướng dẫn Markdown nhanh:

## Định dạng chữ
- Chữ **in đậm** bằng `**hai dấu sao**`
- Chữ _in nghiêng_ bằng `_dấu gạch dưới_`
- ~~Gạch ngang~~ bằng `~~dấu ngã~~`

## Code
Code trong dòng dùng dấu backtick: `print('Hello')`

Khối code dùng ba dấu backtick:
```dart
void main() {
  print('Hello, DevNotes!');
}
```

## Danh sách
- Danh sách gạch đầu dòng dùng `-`
1. Danh sách đánh số dùng số thứ tự

## Danh sách việc
- [x] Cài DevNotes
- [ ] Viết ghi chú đầu tiên
- [ ] Thiết lập đồng bộ Git

Chúc bạn ghi chép vui vẻ!
''',
  );
}
