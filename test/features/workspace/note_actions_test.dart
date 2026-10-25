// Thao tác tạo / đổi tên / xóa note phải chạy THẬT mỗi lần được gọi.
//
// Bug: các thao tác này từng là FutureProvider.family — Riverpod cache kết quả
// theo tham số, nên lần thứ hai với cùng tham số chỉ trả về kết quả cũ mà
// không chạm vào file. Vd tạo "abc", xóa, tạo lại "abc", xóa lần nữa → file
// vẫn còn; đổi tên A→B→A→B thì lần cuối không đổi gì.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

import '../editor/in_memory_note_repository.dart';

void main() {
  late InMemoryNoteRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryNoteRepository();
    container = ProviderContainer(overrides: [
      noteFileRepositoryProvider.overrideWith((ref) async => repo),
    ]);
  });

  tearDown(() => container.dispose());

  NoteActions actions() => container.read(noteActionsProvider);

  test('xóa lại một note cùng đường dẫn lần thứ hai vẫn xóa thật', () async {
    final first = await actions().create(title: 'abc', tags: const []);
    await actions().delete(first.filePath);
    final second = await actions().create(title: 'abc', tags: const []);
    expect(second.filePath, first.filePath);

    await actions().delete(second.filePath);

    expect(repo.notes, isEmpty);
  });

  test('đổi tên qua lại nhiều lần thì lần nào cũng đổi thật', () async {
    var note = await actions().create(title: 'A', tags: const []);
    note = await actions().rename(note.filePath, 'B');
    note = await actions().rename(note.filePath, 'A');
    note = await actions().rename(note.filePath, 'B');

    expect(note.title, 'B');
    expect(repo.notes.keys, [note.filePath]);
  });
}
