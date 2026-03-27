import 'dart:io';
import 'package:archive/archive.dart';

class ExportImportService {
  final String workspacePath;

  ExportImportService({required this.workspacePath});

  Future<String> exportToZip(String outputPath) async {
    final archive = Archive();
    final dir = Directory(workspacePath);
    final files = dir.listSync(recursive: true).whereType<File>();

    for (final file in files) {
      if (!file.path.endsWith('.md')) continue;
      final relativePath = file.path
          .substring(workspacePath.length + 1)
          .replaceAll('\\', '/');
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }

    final zipData = ZipEncoder().encode(archive);
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(zipData);
    return outputPath;
  }

  Future<void> importFromZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      if (file.isFile && file.name.endsWith('.md')) {
        final outputFile = File('$workspacePath/${file.name}');
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      }
    }
  }
}
