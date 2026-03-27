import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/git_sync/domain/conflict_parser.dart';

class ConflictScreen extends StatefulWidget {
  final String filePath;
  const ConflictScreen({super.key, required this.filePath});

  @override
  State<ConflictScreen> createState() => _ConflictScreenState();
}

class _ConflictScreenState extends State<ConflictScreen> {
  late String _rawContent;
  late List<ConflictBlock> _blocks;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    _rawContent = await File(widget.filePath).readAsString();
    _blocks = ConflictParser.parse(_rawContent);
    setState(() => _loading = false);
  }

  Future<void> _resolve(Resolution resolution) async {
    final resolved = ConflictParser.resolveAll(_rawContent, resolution);
    await File(widget.filePath).writeAsString(resolved);
    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    Text('Resolve Conflict',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _blocks.length,
                itemBuilder: (context, index) {
                  final block = _blocks[index];
                  if (block.type == BlockType.clean) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        block.content,
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13),
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.error.withAlpha(100)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.success.withAlpha(30),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LOCAL (yours)',
                                  style: TextStyle(
                                      color: colors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(block.localContent!,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: colors.border),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.accentLight.withAlpha(30),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REMOTE (theirs)',
                                  style: TextStyle(
                                      color: colors.accentLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(block.remoteContent!,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _resolve(Resolution.keepMine),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.success,
                        side: BorderSide(color: colors.success),
                      ),
                      child: const Text('Keep Mine'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _resolve(Resolution.keepTheirs),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accentLight,
                        side: BorderSide(color: colors.accentLight),
                      ),
                      child: const Text('Keep Theirs'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _resolve(Resolution.keepBoth),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent),
                      child: Text('Keep Both',
                          style: TextStyle(color: colors.textOnAccent)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
