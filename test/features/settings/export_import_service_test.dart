import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/settings/data/export_import_service.dart';

void main() {
  late Directory tempDir;
  late Directory workspaceDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_export_test_');
    workspaceDir = Directory('${tempDir.path}/workspace')..createSync();
    File('${workspaceDir.path}/note1.md').writeAsStringSync('# Note 1');
    File('${workspaceDir.path}/note2.md').writeAsStringSync('# Note 2');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ExportImportService', () {
    test('exportToZip creates zip file', () async {
      final service = ExportImportService(workspacePath: workspaceDir.path);
      final zipPath = await service.exportToZip('${tempDir.path}/export.zip');
      expect(File(zipPath).existsSync(), isTrue);
      expect(File(zipPath).lengthSync(), greaterThan(0));
    });

    test('importFromZip extracts files to workspace', () async {
      final service = ExportImportService(workspacePath: workspaceDir.path);
      final zipPath = await service.exportToZip('${tempDir.path}/export.zip');

      final importDir = Directory('${tempDir.path}/import_workspace')
        ..createSync();
      final importService =
          ExportImportService(workspacePath: importDir.path);
      await importService.importFromZip(zipPath);

      final files = importDir.listSync().whereType<File>().toList();
      expect(files.length, 2);
    });
  });
}
