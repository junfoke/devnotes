import 'package:flutter/material.dart';

class ConflictScreen extends StatelessWidget {
  const ConflictScreen({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Conflict: $filePath'),
      ),
    );
  }
}
