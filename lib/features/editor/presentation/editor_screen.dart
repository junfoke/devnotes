import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Editor: $filePath'),
      ),
    );
  }
}
