// lib/core/file_system/workspace_path_provider.dart
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class WorkspacePathProvider {
  static Future<String> getWorkspacePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final workspace = Directory('${appDir.path}/devnotes_workspace');
    if (!workspace.existsSync()) {
      workspace.createSync(recursive: true);
    }
    return workspace.path;
  }
}
