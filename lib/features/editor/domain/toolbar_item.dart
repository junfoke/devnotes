import 'package:flutter/material.dart';

class ToolbarItem {
  final String id;
  final String label;
  final IconData? icon;
  final String insertBefore;
  final String insertAfter;
  final bool isBlock;

  const ToolbarItem({
    required this.id,
    required this.label,
    this.icon,
    required this.insertBefore,
    this.insertAfter = '',
    this.isBlock = false,
  });

  static const allItems = [
    ToolbarItem(id: 'h1', label: 'H1', insertBefore: '# ', isBlock: true),
    ToolbarItem(id: 'h2', label: 'H2', insertBefore: '## ', isBlock: true),
    ToolbarItem(id: 'h3', label: 'H3', insertBefore: '### ', isBlock: true),
    ToolbarItem(id: 'bold', label: 'B', icon: Icons.format_bold, insertBefore: '**', insertAfter: '**'),
    ToolbarItem(id: 'italic', label: 'I', icon: Icons.format_italic, insertBefore: '_', insertAfter: '_'),
    ToolbarItem(id: 'strikethrough', label: 'S', icon: Icons.strikethrough_s, insertBefore: '~~', insertAfter: '~~'),
    ToolbarItem(id: 'link', label: 'Link', icon: Icons.link, insertBefore: '[', insertAfter: '](url)'),
    ToolbarItem(id: 'image', label: 'Img', icon: Icons.image, insertBefore: '![alt](', insertAfter: ')'),
    ToolbarItem(id: 'code_inline', label: '`', icon: Icons.code, insertBefore: '`', insertAfter: '`'),
    ToolbarItem(id: 'code_block', label: '<>', insertBefore: '```\n', insertAfter: '\n```', isBlock: true),
    ToolbarItem(id: 'checklist', label: '[]', icon: Icons.check_box_outlined, insertBefore: '- [ ] ', isBlock: true),
    ToolbarItem(id: 'list_unordered', label: '•', icon: Icons.format_list_bulleted, insertBefore: '- ', isBlock: true),
    ToolbarItem(id: 'list_ordered', label: '1.', icon: Icons.format_list_numbered, insertBefore: '1. ', isBlock: true),
    ToolbarItem(id: 'quote', label: '>', icon: Icons.format_quote, insertBefore: '> ', isBlock: true),
    ToolbarItem(id: 'table', label: 'T', icon: Icons.table_chart, insertBefore: '| Col1 | Col2 |\n|------|------|\n| ', insertAfter: ' |  |', isBlock: true),
    ToolbarItem(id: 'hr', label: '—', insertBefore: '\n---\n', isBlock: true),
  ];
}
