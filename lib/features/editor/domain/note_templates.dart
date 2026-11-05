/// Mẫu ghi chú dựng sẵn cho công cụ "Mẫu".
class NoteTemplate {
  final String id;
  final String title;
  final String body;

  const NoteTemplate({
    required this.id,
    required this.title,
    required this.body,
  });
}

/// Mẫu dựng sẵn: `vi` → tiếng Việt, ngôn ngữ khác → tiếng Anh. Cùng bộ id.
List<NoteTemplate> builtInTemplates(String languageCode) =>
    languageCode == 'vi' ? _vi : _en;

const _vi = [
  NoteTemplate(
    id: 'meeting',
    title: 'Biên bản họp',
    body: '''## Biên bản họp

**Ngày:** 
**Người tham dự:** 

### Nội dung

- 

### Quyết định

- 

### Việc cần làm

- [ ] 
''',
  ),
  NoteTemplate(
    id: 'bug_report',
    title: 'Báo cáo lỗi',
    body: '''## Báo cáo lỗi

**Mô tả ngắn:** 

### Các bước tái hiện

1. 

### Kết quả mong đợi

### Kết quả thực tế

### Môi trường

- 
''',
  ),
  NoteTemplate(
    id: 'journal',
    title: 'Nhật ký',
    body: '''## Nhật ký

**Ngày:** 

### Hôm nay mình đã làm

- 

### Điều học được

- 

### Ngày mai

- [ ] 
''',
  ),
];

const _en = [
  NoteTemplate(
    id: 'meeting',
    title: 'Meeting notes',
    body: '''## Meeting notes

**Date:** 
**Attendees:** 

### Discussion

- 

### Decisions

- 

### Action items

- [ ] 
''',
  ),
  NoteTemplate(
    id: 'bug_report',
    title: 'Bug report',
    body: '''## Bug report

**Summary:** 

### Steps to reproduce

1. 

### Expected result

### Actual result

### Environment

- 
''',
  ),
  NoteTemplate(
    id: 'journal',
    title: 'Journal',
    body: '''## Journal

**Date:** 

### What I did today

- 

### What I learned

- 

### Tomorrow

- [ ] 
''',
  ),
];
