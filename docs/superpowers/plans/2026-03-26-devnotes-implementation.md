# DevNotes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-first Markdown note-taking mobile app for developers with Git sync, full-text search, and customizable editor.

**Architecture:** Monolithic feature-first Flutter app. All data stored as `.md` files with YAML frontmatter. Sync via Git (libgit2dart). Search via SQLite FTS5 in isolate. State managed with Riverpod.

**Tech Stack:** Flutter, flutter_riverpod, go_router, libgit2dart, flutter_markdown, flutter_highlight, flutter_secure_storage, sqlite3_flutter_libs, tutorial_coach_mark

**Spec:** `docs/superpowers/specs/2026-03-26-devnotes-full-design.md`

---

## Phase 1: Project Setup & Core Infrastructure

### Task 1: Initialize Flutter Project & Dependencies

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `analysis_options.yaml`

- [ ] **Step 1: Create Flutter project**

```bash
flutter create --org com.devnotes --project-name devnotes --platforms android,ios .
```

- [ ] **Step 2: Replace pubspec.yaml dependencies**

```yaml
name: devnotes
description: Local-first Markdown note-taking app for developers.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.6.0
  flutter: ">=3.27.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1
  path_provider: ^2.1.5
  yaml: ^3.1.3
  yaml_writer: ^2.0.0
  flutter_markdown: ^0.7.6
  flutter_highlight: ^0.7.0
  highlight: ^0.7.0
  flutter_secure_storage: ^9.2.4
  sqlite3_flutter_libs: ^0.5.28
  sqlite3: ^2.7.3
  libgit2dart: ^1.7.2
  tutorial_coach_mark: ^1.2.11
  shared_preferences: ^2.3.5
  intl: ^0.19.0
  share_plus: ^10.1.4
  archive: ^4.0.4
  uuid: ^4.5.1
  equatable: ^2.0.7
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.14
  json_serializable: ^6.9.4
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  fonts:
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
    - family: FiraCode
      fonts:
        - asset: assets/fonts/FiraCode-Regular.ttf
        - asset: assets/fonts/FiraCode-Bold.ttf
          weight: 700
```

- [ ] **Step 3: Install dependencies**

```bash
flutter pub get
```

- [ ] **Step 4: Create folder structure**

```bash
mkdir -p lib/app
mkdir -p lib/features/workspace/{presentation,application,domain,data}
mkdir -p lib/features/editor/{presentation,application,domain,data}
mkdir -p lib/features/git_sync/{presentation,application,domain,data}
mkdir -p lib/features/settings/{presentation,application,domain,data}
mkdir -p lib/features/onboarding/{presentation,application}
mkdir -p lib/core/{file_system,git_client,search_engine,theme,utils}
mkdir -p test/features/workspace
mkdir -p test/features/editor
mkdir -p test/features/git_sync
mkdir -p test/features/settings
mkdir -p test/core/{file_system,search_engine,theme,utils}
mkdir -p assets/fonts
mkdir -p assets/images
```

- [ ] **Step 5: Commit**

```bash
git init
git add -A
git commit -m "chore: initialize Flutter project with dependencies and folder structure"
```

---

### Task 2: Core Models & Enums

**Files:**
- Create: `lib/features/workspace/domain/note_file.dart`
- Create: `lib/features/workspace/domain/collection.dart`
- Create: `lib/features/git_sync/domain/sync_state.dart`
- Create: `lib/features/git_sync/domain/git_config.dart`
- Create: `lib/features/settings/domain/editor_preferences.dart`
- Create: `lib/core/utils/enums.dart`
- Test: `test/features/workspace/note_file_test.dart`
- Test: `test/features/workspace/collection_test.dart`

- [ ] **Step 1: Write test for NoteFile model**

```dart
// test/features/workspace/note_file_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/core/utils/enums.dart';

void main() {
  group('NoteFile', () {
    test('creates with required fields', () {
      final note = NoteFile(
        filePath: '/notes/test.md',
        title: 'Test Note',
        tags: ['flutter', 'dart'],
        createdAt: DateTime.parse('2026-03-26T10:00:00Z'),
        updatedAt: DateTime.parse('2026-03-26T10:30:00Z'),
        syncStatus: SyncStatus.synced,
        content: '# Hello World',
      );

      expect(note.filePath, '/notes/test.md');
      expect(note.title, 'Test Note');
      expect(note.tags, ['flutter', 'dart']);
      expect(note.syncStatus, SyncStatus.synced);
      expect(note.content, '# Hello World');
      expect(note.conflictRef, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final note = NoteFile(
        filePath: '/notes/test.md',
        title: 'Test Note',
        tags: [],
        createdAt: DateTime.parse('2026-03-26T10:00:00Z'),
        updatedAt: DateTime.parse('2026-03-26T10:00:00Z'),
        syncStatus: SyncStatus.synced,
        content: '',
      );

      final updated = note.copyWith(title: 'Updated', syncStatus: SyncStatus.pending);
      expect(updated.title, 'Updated');
      expect(updated.syncStatus, SyncStatus.pending);
      expect(updated.filePath, '/notes/test.md');
    });

    test('equality based on filePath', () {
      final a = NoteFile(
        filePath: '/notes/test.md',
        title: 'A',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        content: '',
      );
      final b = NoteFile(
        filePath: '/notes/test.md',
        title: 'B',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        content: '',
      );
      expect(a, equals(b));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/workspace/note_file_test.dart
```
Expected: FAIL — imports not found

- [ ] **Step 3: Create enums**

```dart
// lib/core/utils/enums.dart
enum SyncStatus { synced, pending, conflict }

enum SyncAction { push, pull, conflict }

enum SyncFrequency { manual, onSave, periodic }

enum ThemePreference { dark, light, system }
```

- [ ] **Step 4: Create NoteFile model**

```dart
// lib/features/workspace/domain/note_file.dart
import 'package:equatable/equatable.dart';
import 'package:devnotes/core/utils/enums.dart';

class NoteFile extends Equatable {
  final String filePath;
  final String title;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? conflictRef;
  final String content;

  const NoteFile({
    required this.filePath,
    required this.title,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.conflictRef,
    required this.content,
  });

  NoteFile copyWith({
    String? filePath,
    String? title,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? conflictRef,
    String? content,
  }) {
    return NoteFile(
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      conflictRef: conflictRef ?? this.conflictRef,
      content: content ?? this.content,
    );
  }

  @override
  List<Object?> get props => [filePath];
}
```

- [ ] **Step 5: Run NoteFile test**

```bash
flutter test test/features/workspace/note_file_test.dart
```
Expected: PASS

- [ ] **Step 6: Write test for Collection model**

```dart
// test/features/workspace/collection_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';

void main() {
  group('Collection', () {
    test('creates with fields', () {
      final col = Collection(
        id: 'col-1',
        name: 'Flutter',
        filterTags: ['flutter', 'dart'],
        icon: Icons.folder,
        color: Colors.purple,
      );
      expect(col.name, 'Flutter');
      expect(col.filterTags, ['flutter', 'dart']);
    });

    test('toJson and fromJson roundtrip', () {
      final col = Collection(
        id: 'col-1',
        name: 'Flutter',
        filterTags: ['flutter'],
        icon: Icons.folder,
        color: Colors.purple,
      );
      final json = col.toJson();
      final restored = Collection.fromJson(json);
      expect(restored.name, 'Flutter');
      expect(restored.filterTags, ['flutter']);
      expect(restored.id, 'col-1');
    });
  });
}
```

- [ ] **Step 7: Create Collection model**

```dart
// lib/features/workspace/domain/collection.dart
import 'package:flutter/material.dart';

class Collection {
  final String id;
  final String name;
  final List<String> filterTags;
  final IconData icon;
  final Color color;

  const Collection({
    required this.id,
    required this.name,
    required this.filterTags,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filterTags': filterTags,
        'iconCodePoint': icon.codePoint,
        'colorValue': color.value,
      };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        name: json['name'] as String,
        filterTags: List<String>.from(json['filterTags'] as List),
        icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
        color: Color(json['colorValue'] as int),
      );

  Collection copyWith({
    String? id,
    String? name,
    List<String>? filterTags,
    IconData? icon,
    Color? color,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      filterTags: filterTags ?? this.filterTags,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
```

- [ ] **Step 8: Run Collection test**

```bash
flutter test test/features/workspace/collection_test.dart
```
Expected: PASS

- [ ] **Step 9: Create remaining models**

```dart
// lib/features/git_sync/domain/sync_state.dart
import 'package:devnotes/core/utils/enums.dart';

class SyncState {
  final String branchName;
  final SyncStatus status;
  final DateTime? lastSyncAt;
  final List<SyncLogEntry> history;

  const SyncState({
    required this.branchName,
    required this.status,
    this.lastSyncAt,
    this.history = const [],
  });

  SyncState copyWith({
    String? branchName,
    SyncStatus? status,
    DateTime? lastSyncAt,
    List<SyncLogEntry>? history,
  }) {
    return SyncState(
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      history: history ?? this.history,
    );
  }
}

class SyncLogEntry {
  final DateTime timestamp;
  final SyncAction action;
  final int filesChanged;
  final bool success;
  final String? errorMessage;

  const SyncLogEntry({
    required this.timestamp,
    required this.action,
    required this.filesChanged,
    required this.success,
    this.errorMessage,
  });
}
```

```dart
// lib/features/git_sync/domain/git_config.dart
class GitConfig {
  final String remoteUrl;
  final String username;
  final String pat;

  const GitConfig({
    required this.remoteUrl,
    required this.username,
    required this.pat,
  });

  GitConfig copyWith({
    String? remoteUrl,
    String? username,
    String? pat,
  }) {
    return GitConfig(
      remoteUrl: remoteUrl ?? this.remoteUrl,
      username: username ?? this.username,
      pat: pat ?? this.pat,
    );
  }
}
```

```dart
// lib/features/settings/domain/editor_preferences.dart
import 'package:devnotes/core/utils/enums.dart';

class EditorPreferences {
  final double fontSize;
  final String fontFamily;
  final Duration autoSaveInterval;
  final List<String> toolbarItems;
  final SyncFrequency syncFrequency;
  final Duration? periodicInterval;

  const EditorPreferences({
    this.fontSize = 14.0,
    this.fontFamily = 'JetBrains Mono',
    this.autoSaveInterval = const Duration(seconds: 3),
    this.toolbarItems = defaultToolbarItems,
    this.syncFrequency = SyncFrequency.manual,
    this.periodicInterval,
  });

  static const defaultToolbarItems = [
    'h1', 'h2', 'h3', 'bold', 'italic', 'strikethrough',
    'link', 'image', 'code_inline', 'code_block', 'checklist',
    'list_ordered', 'list_unordered', 'quote', 'table', 'hr',
  ];

  EditorPreferences copyWith({
    double? fontSize,
    String? fontFamily,
    Duration? autoSaveInterval,
    List<String>? toolbarItems,
    SyncFrequency? syncFrequency,
    Duration? periodicInterval,
  }) {
    return EditorPreferences(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      toolbarItems: toolbarItems ?? this.toolbarItems,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      periodicInterval: periodicInterval ?? this.periodicInterval,
    );
  }
}
```

- [ ] **Step 10: Run all tests**

```bash
flutter test
```
Expected: ALL PASS

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "feat: add core domain models — NoteFile, Collection, SyncState, GitConfig, EditorPreferences"
```

---

### Task 3: Theme System (Dark/Light/System)

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/theme_provider.dart`
- Test: `test/core/theme/app_theme_test.dart`

- [ ] **Step 1: Write test for theme colors and ThemeData**

```dart
// test/core/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('dark colors are defined', () {
      expect(AppColors.dark.bgPrimary, isA<Color>());
      expect(AppColors.dark.accent, isA<Color>());
      expect(AppColors.dark.textPrimary, isA<Color>());
    });

    test('light colors are defined', () {
      expect(AppColors.light.bgPrimary, isA<Color>());
      expect(AppColors.light.accent, isA<Color>());
      expect(AppColors.light.textPrimary, isA<Color>());
    });
  });

  group('AppTheme', () {
    test('dark theme has dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('light theme has light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme uses accent color as colorSchemeSeed', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.primary, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/theme/app_theme_test.dart
```
Expected: FAIL

- [ ] **Step 3: Create AppColors**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColorScheme {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgSurface;
  final Color accent;
  final Color accentLight;
  final Color accentSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;
  final Color border;
  final Color codeBg;
  final Color success;
  final Color error;
  final Color warning;
  final Color fabBg;

  const AppColorScheme({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgSurface,
    required this.accent,
    required this.accentLight,
    required this.accentSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.border,
    required this.codeBg,
    required this.success,
    required this.error,
    required this.warning,
    required this.fabBg,
  });
}

class AppColors {
  static const dark = AppColorScheme(
    bgPrimary: Color(0xFF0F0F1A),
    bgSecondary: Color(0xFF1A1A2E),
    bgTertiary: Color(0xFF16162A),
    bgSurface: Color(0xFF252540),
    accent: Color(0xFF7C3AED),
    accentLight: Color(0xFFA78BFA),
    accentSurface: Color(0xFF1E1040),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    textOnAccent: Color(0xFFFFFFFF),
    border: Color(0xFF2D2D4A),
    codeBg: Color(0xFF1E1E3A),
    success: Color(0xFF22C55E),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    fabBg: Color(0xFF7C3AED),
  );

  static const light = AppColorScheme(
    bgPrimary: Color(0xFFF8FAFC),
    bgSecondary: Color(0xFFF1F5F9),
    bgTertiary: Color(0xFFE2E8F0),
    bgSurface: Color(0xFFFFFFFF),
    accent: Color(0xFF7C3AED),
    accentLight: Color(0xFF8B5CF6),
    accentSurface: Color(0xFFF3EEFF),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    textOnAccent: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    codeBg: Color(0xFFF1F5F9),
    success: Color(0xFF16A34A),
    error: Color(0xFFDC2626),
    warning: Color(0xFFD97706),
    fabBg: Color(0xFF7C3AED),
  );
}
```

- [ ] **Step 4: Create AppTheme**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_colors.dart';

extension AppColorsExtension on ThemeData {
  AppColorScheme get appColors =>
      brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}

class AppTheme {
  static ThemeData dark() {
    final colors = AppColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.bgPrimary,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        secondary: colors.accentLight,
        surface: colors.bgSurface,
        error: colors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      fontFamily: 'Inter',
      dividerColor: colors.border,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.fabBg,
        foregroundColor: colors.textOnAccent,
      ),
    );
  }

  static ThemeData light() {
    final colors = AppColors.light;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.bgPrimary,
      colorScheme: ColorScheme.light(
        primary: colors.accent,
        secondary: colors.accentLight,
        surface: colors.bgSurface,
        error: colors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      fontFamily: 'Inter',
      dividerColor: colors.border,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.fabBg,
        foregroundColor: colors.textOnAccent,
      ),
    );
  }
}
```

- [ ] **Step 5: Create theme provider**

```dart
// lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class ThemeNotifier extends StateNotifier<ThemePreference> {
  ThemeNotifier() : super(ThemePreference.dark) {
    _load();
  }

  static const _key = 'theme_preference';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = ThemePreference.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemePreference.dark,
      );
    }
  }

  Future<void> setTheme(ThemePreference pref) async {
    state = pref;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, pref.name);
  }

  ThemeData resolveTheme(Brightness platformBrightness) {
    switch (state) {
      case ThemePreference.dark:
        return AppTheme.dark();
      case ThemePreference.light:
        return AppTheme.light();
      case ThemePreference.system:
        return platformBrightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light();
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemePreference>(
  (ref) => ThemeNotifier(),
);
```

- [ ] **Step 6: Run tests**

```bash
flutter test test/core/theme/app_theme_test.dart
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add theme system with dark/light/system support and color tokens"
```

---

### Task 4: Router Setup (go_router)

**Files:**
- Create: `lib/app/router.dart`
- Create: `lib/app/app.dart`
- Modify: `lib/main.dart`
- Create: placeholder screens for each route

- [ ] **Step 1: Create placeholder screens**

```dart
// lib/features/workspace/presentation/workspace_screen.dart
import 'package:flutter/material.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Workspace Explorer')),
    );
  }
}
```

```dart
// lib/features/editor/presentation/editor_screen.dart
import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  final String filePath;
  const EditorScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Editor: $filePath')),
    );
  }
}
```

```dart
// lib/features/git_sync/presentation/git_setup_screen.dart
import 'package:flutter/material.dart';

class GitSetupScreen extends StatelessWidget {
  const GitSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Git Setup')),
    );
  }
}
```

```dart
// lib/features/git_sync/presentation/conflict_screen.dart
import 'package:flutter/material.dart';

class ConflictScreen extends StatelessWidget {
  final String filePath;
  const ConflictScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Conflict: $filePath')),
    );
  }
}
```

```dart
// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Settings')),
    );
  }
}
```

```dart
// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Onboarding')),
    );
  }
}
```

```dart
// lib/features/onboarding/presentation/onboarding_git_screen.dart
import 'package:flutter/material.dart';

class OnboardingGitScreen extends StatelessWidget {
  const OnboardingGitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Onboarding Git Setup')),
    );
  }
}
```

```dart
// lib/features/onboarding/presentation/onboarding_first_note_screen.dart
import 'package:flutter/material.dart';

class OnboardingFirstNoteScreen extends StatelessWidget {
  const OnboardingFirstNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('First Note')),
    );
  }
}
```

- [ ] **Step 2: Create router**

```dart
// lib/app/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/features/workspace/presentation/workspace_screen.dart';
import 'package:devnotes/features/editor/presentation/editor_screen.dart';
import 'package:devnotes/features/git_sync/presentation/git_setup_screen.dart';
import 'package:devnotes/features/git_sync/presentation/conflict_screen.dart';
import 'package:devnotes/features/settings/presentation/settings_screen.dart';
import 'package:devnotes/features/onboarding/presentation/onboarding_screen.dart';
import 'package:devnotes/features/onboarding/presentation/onboarding_git_screen.dart';
import 'package:devnotes/features/onboarding/presentation/onboarding_first_note_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarding_complete') ?? false;
      if (!onboarded && !state.matchedLocation.startsWith('/onboarding')) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WorkspaceScreen(),
      ),
      GoRoute(
        path: '/editor/:filePath',
        builder: (context, state) => EditorScreen(
          filePath: Uri.decodeComponent(state.pathParameters['filePath']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/git',
        builder: (context, state) => const GitSetupScreen(),
      ),
      GoRoute(
        path: '/conflict/:filePath',
        builder: (context, state) => ConflictScreen(
          filePath: Uri.decodeComponent(state.pathParameters['filePath']!),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/git',
        builder: (context, state) => const OnboardingGitScreen(),
      ),
      GoRoute(
        path: '/onboarding/first-note',
        builder: (context, state) => const OnboardingFirstNoteScreen(),
      ),
    ],
  );
});
```

- [ ] **Step 3: Create App widget**

```dart
// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/app/router.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class DevNotesApp extends ConsumerWidget {
  const DevNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);

    final themeNotifier = ref.read(themeProvider.notifier);
    final themeData = themeNotifier.resolveTheme(brightness);

    return MaterialApp.router(
      title: 'DevNotes',
      theme: themeData,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 4: Update main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DevNotesApp(),
    ),
  );
}
```

- [ ] **Step 5: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add go_router setup with all routes and placeholder screens"
```

---

## Phase 2: File System & Data Layer

### Task 5: YAML Frontmatter Parser

**Files:**
- Create: `lib/core/file_system/frontmatter_parser.dart`
- Test: `test/core/file_system/frontmatter_parser_test.dart`

- [ ] **Step 1: Write tests for parser**

```dart
// test/core/file_system/frontmatter_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/file_system/frontmatter_parser.dart';

void main() {
  group('FrontmatterParser', () {
    test('parse extracts frontmatter and content', () {
      const raw = '''---
title: "Test Note"
tags: ["flutter", "dart"]
createdAt: "2026-03-26T10:00:00Z"
updatedAt: "2026-03-26T10:30:00Z"
---

# Hello World
This is content.''';

      final result = FrontmatterParser.parse(raw);
      expect(result.title, 'Test Note');
      expect(result.tags, ['flutter', 'dart']);
      expect(result.createdAt, DateTime.parse('2026-03-26T10:00:00Z'));
      expect(result.content, '# Hello World\nThis is content.');
    });

    test('parse handles file without frontmatter', () {
      const raw = '# Just Content\nNo frontmatter here.';
      final result = FrontmatterParser.parse(raw);
      expect(result.title, '');
      expect(result.tags, isEmpty);
      expect(result.content, raw);
    });

    test('parse handles empty tags', () {
      const raw = '''---
title: "No Tags"
tags: []
createdAt: "2026-03-26T10:00:00Z"
updatedAt: "2026-03-26T10:00:00Z"
---

Content here.''';

      final result = FrontmatterParser.parse(raw);
      expect(result.tags, isEmpty);
    });

    test('serialize creates valid frontmatter string', () {
      final output = FrontmatterParser.serialize(
        title: 'My Note',
        tags: ['flutter', 'idea'],
        createdAt: DateTime.parse('2026-03-26T10:00:00Z'),
        updatedAt: DateTime.parse('2026-03-26T10:30:00Z'),
        content: '# Hello\nWorld',
      );

      expect(output, contains('title: "My Note"'));
      expect(output, contains('tags:'));
      expect(output, contains('- "flutter"'));
      expect(output, contains('# Hello\nWorld'));
    });

    test('roundtrip parse -> serialize -> parse', () {
      final original = FrontmatterParser.serialize(
        title: 'Roundtrip',
        tags: ['test'],
        createdAt: DateTime.parse('2026-03-26T10:00:00Z'),
        updatedAt: DateTime.parse('2026-03-26T10:00:00Z'),
        content: '# Test\nContent here.',
      );

      final parsed = FrontmatterParser.parse(original);
      expect(parsed.title, 'Roundtrip');
      expect(parsed.tags, ['test']);
      expect(parsed.content, '# Test\nContent here.');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/file_system/frontmatter_parser_test.dart
```
Expected: FAIL

- [ ] **Step 3: Implement FrontmatterParser**

```dart
// lib/core/file_system/frontmatter_parser.dart
import 'package:yaml/yaml.dart';

class ParsedNote {
  final String title;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String content;

  const ParsedNote({
    required this.title,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
  });
}

class FrontmatterParser {
  static final _frontmatterRegex = RegExp(r'^---\s*\n([\s\S]*?)\n---\s*\n?');

  static ParsedNote parse(String raw) {
    final match = _frontmatterRegex.firstMatch(raw);
    if (match == null) {
      return ParsedNote(
        title: '',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: raw,
      );
    }

    final yamlStr = match.group(1)!;
    final content = raw.substring(match.end).trim();
    final yaml = loadYaml(yamlStr) as YamlMap;

    final title = (yaml['title'] as String?) ?? '';
    final tags = yaml['tags'] != null
        ? List<String>.from(yaml['tags'] as YamlList)
        : <String>[];
    final createdAt = DateTime.parse(yaml['createdAt'] as String);
    final updatedAt = DateTime.parse(yaml['updatedAt'] as String);

    return ParsedNote(
      title: title,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      content: content,
    );
  }

  static String serialize({
    required String title,
    required List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String content,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('title: "$title"');
    buffer.writeln('tags:');
    for (final tag in tags) {
      buffer.writeln('- "$tag"');
    }
    if (tags.isEmpty) {
      buffer.writeln('  []');
    }
    buffer.writeln('createdAt: "${createdAt.toUtc().toIso8601String()}"');
    buffer.writeln('updatedAt: "${updatedAt.toUtc().toIso8601String()}"');
    buffer.writeln('---');
    buffer.writeln();
    buffer.write(content);
    return buffer.toString();
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/file_system/frontmatter_parser_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add YAML frontmatter parser with parse/serialize roundtrip"
```

---

### Task 6: File System Repository

**Files:**
- Create: `lib/core/file_system/note_file_repository.dart`
- Create: `lib/core/file_system/workspace_path_provider.dart`
- Test: `test/core/file_system/note_file_repository_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/core/file_system/note_file_repository_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/core/file_system/frontmatter_parser.dart';

void main() {
  late Directory tempDir;
  late NoteFileRepository repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_test_');
    repo = NoteFileRepository(workspacePath: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('NoteFileRepository', () {
    test('createNote creates .md file with frontmatter', () async {
      final note = await repo.createNote(title: 'Test Note', tags: ['dart']);
      expect(note.title, 'Test Note');
      expect(note.tags, ['dart']);

      final file = File(note.filePath);
      expect(file.existsSync(), isTrue);

      final raw = file.readAsStringSync();
      final parsed = FrontmatterParser.parse(raw);
      expect(parsed.title, 'Test Note');
    });

    test('listNotes returns all .md files', () async {
      await repo.createNote(title: 'Note 1', tags: []);
      await repo.createNote(title: 'Note 2', tags: []);

      final notes = await repo.listNotes();
      expect(notes.length, 2);
    });

    test('readNote reads existing file', () async {
      final created = await repo.createNote(title: 'Read Me', tags: ['test']);
      final read = await repo.readNote(created.filePath);
      expect(read.title, 'Read Me');
      expect(read.tags, ['test']);
    });

    test('saveNote writes updated content', () async {
      final note = await repo.createNote(title: 'Original', tags: []);
      final updated = note.copyWith(
        title: 'Updated Title',
        content: '# Updated Content',
      );
      await repo.saveNote(updated);

      final read = await repo.readNote(note.filePath);
      expect(read.title, 'Updated Title');
      expect(read.content, '# Updated Content');
    });

    test('deleteNote removes file', () async {
      final note = await repo.createNote(title: 'Delete Me', tags: []);
      await repo.deleteNote(note.filePath);

      final file = File(note.filePath);
      expect(file.existsSync(), isFalse);
    });

    test('renameNote moves file and updates title', () async {
      final note = await repo.createNote(title: 'Old Name', tags: []);
      final renamed = await repo.renameNote(note.filePath, 'New Name');
      expect(renamed.title, 'New Name');
      expect(File(note.filePath).existsSync(), isFalse);
      expect(File(renamed.filePath).existsSync(), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/file_system/note_file_repository_test.dart
```
Expected: FAIL

- [ ] **Step 3: Create workspace path provider**

```dart
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
```

- [ ] **Step 4: Implement NoteFileRepository**

```dart
// lib/core/file_system/note_file_repository.dart
import 'dart:io';
import 'package:devnotes/core/file_system/frontmatter_parser.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/core/utils/enums.dart';

class NoteFileRepository {
  final String workspacePath;

  NoteFileRepository({required this.workspacePath});

  String _sanitizeFileName(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  String _uniqueFilePath(String title) {
    final baseName = _sanitizeFileName(title);
    var filePath = '$workspacePath/$baseName.md';
    var counter = 1;
    while (File(filePath).existsSync()) {
      filePath = '$workspacePath/$baseName-$counter.md';
      counter++;
    }
    return filePath;
  }

  Future<NoteFile> createNote({
    required String title,
    required List<String> tags,
  }) async {
    final now = DateTime.now().toUtc();
    final filePath = _uniqueFilePath(title);
    final content = '';

    final raw = FrontmatterParser.serialize(
      title: title,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      content: content,
    );

    final file = File(filePath);
    await file.writeAsString(raw);

    return NoteFile(
      filePath: filePath,
      title: title,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      content: content,
    );
  }

  Future<List<NoteFile>> listNotes() async {
    final dir = Directory(workspacePath);
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();

    final notes = <NoteFile>[];
    for (final file in files) {
      final raw = await file.readAsString();
      final parsed = FrontmatterParser.parse(raw);
      notes.add(NoteFile(
        filePath: file.path,
        title: parsed.title,
        tags: parsed.tags,
        createdAt: parsed.createdAt,
        updatedAt: parsed.updatedAt,
        syncStatus: SyncStatus.synced,
        content: parsed.content,
      ));
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<NoteFile> readNote(String filePath) async {
    final file = File(filePath);
    final raw = await file.readAsString();
    final parsed = FrontmatterParser.parse(raw);

    return NoteFile(
      filePath: filePath,
      title: parsed.title,
      tags: parsed.tags,
      createdAt: parsed.createdAt,
      updatedAt: parsed.updatedAt,
      syncStatus: SyncStatus.synced,
      content: parsed.content,
    );
  }

  Future<void> saveNote(NoteFile note) async {
    final raw = FrontmatterParser.serialize(
      title: note.title,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: DateTime.now().toUtc(),
      content: note.content,
    );

    final file = File(note.filePath);
    await file.writeAsString(raw);
  }

  Future<void> deleteNote(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<NoteFile> renameNote(String oldPath, String newTitle) async {
    final note = await readNote(oldPath);
    final newPath = _uniqueFilePath(newTitle);

    final updated = note.copyWith(
      filePath: newPath,
      title: newTitle,
      updatedAt: DateTime.now().toUtc(),
    );

    await saveNote(updated);
    await deleteNote(oldPath);

    return updated;
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/core/file_system/note_file_repository_test.dart
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add NoteFileRepository with CRUD operations for .md files"
```

---

### Task 7: SQLite Metadata Database

**Files:**
- Create: `lib/core/file_system/metadata_database.dart`
- Test: `test/core/file_system/metadata_database_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/core/file_system/metadata_database_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/utils/enums.dart';

void main() {
  late MetadataDatabase db;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_db_test_');
    db = MetadataDatabase(dbPath: '${tempDir.path}/metadata.db');
  });

  tearDown(() {
    db.close();
    tempDir.deleteSync(recursive: true);
  });

  group('MetadataDatabase', () {
    test('upsertSyncStatus and getSyncStatus', () {
      db.upsertSyncStatus('/notes/test.md', SyncStatus.pending);
      final status = db.getSyncStatus('/notes/test.md');
      expect(status, SyncStatus.pending);
    });

    test('getSyncStatus returns synced for unknown file', () {
      final status = db.getSyncStatus('/notes/unknown.md');
      expect(status, SyncStatus.synced);
    });

    test('setConflictRef and getConflictRef', () {
      db.setConflictRef('/notes/test.md', '/notes/test_CONFLICT.md');
      final ref = db.getConflictRef('/notes/test.md');
      expect(ref, '/notes/test_CONFLICT.md');
    });

    test('clearConflictRef sets null', () {
      db.setConflictRef('/notes/test.md', '/conflict.md');
      db.clearConflictRef('/notes/test.md');
      final ref = db.getConflictRef('/notes/test.md');
      expect(ref, isNull);
    });

    test('deleteFileMetadata removes record', () {
      db.upsertSyncStatus('/notes/test.md', SyncStatus.pending);
      db.deleteFileMetadata('/notes/test.md');
      final status = db.getSyncStatus('/notes/test.md');
      expect(status, SyncStatus.synced);
    });

    test('addSyncLogEntry and getSyncLog', () {
      db.addSyncLogEntry(
        action: SyncAction.push,
        filesChanged: 3,
        success: true,
      );
      db.addSyncLogEntry(
        action: SyncAction.pull,
        filesChanged: 1,
        success: false,
        errorMessage: 'Network error',
      );

      final log = db.getSyncLog(limit: 10);
      expect(log.length, 2);
      expect(log[0].action, SyncAction.pull);
      expect(log[0].success, false);
      expect(log[1].action, SyncAction.push);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/file_system/metadata_database_test.dart
```
Expected: FAIL

- [ ] **Step 3: Implement MetadataDatabase**

```dart
// lib/core/file_system/metadata_database.dart
import 'package:sqlite3/sqlite3.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';

class MetadataDatabase {
  final Database _db;

  MetadataDatabase({required String dbPath}) : _db = sqlite3.open(dbPath) {
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS file_metadata (
        file_path TEXT PRIMARY KEY,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        conflict_ref TEXT
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        action TEXT NOT NULL,
        files_changed INTEGER NOT NULL,
        success INTEGER NOT NULL,
        error_message TEXT
      )
    ''');
  }

  void upsertSyncStatus(String filePath, SyncStatus status) {
    _db.execute(
      '''INSERT INTO file_metadata (file_path, sync_status) VALUES (?, ?)
         ON CONFLICT(file_path) DO UPDATE SET sync_status = ?''',
      [filePath, status.name, status.name],
    );
  }

  SyncStatus getSyncStatus(String filePath) {
    final result = _db.select(
      'SELECT sync_status FROM file_metadata WHERE file_path = ?',
      [filePath],
    );
    if (result.isEmpty) return SyncStatus.synced;
    return SyncStatus.values.firstWhere(
      (e) => e.name == result.first['sync_status'],
      orElse: () => SyncStatus.synced,
    );
  }

  void setConflictRef(String filePath, String conflictRef) {
    _db.execute(
      '''INSERT INTO file_metadata (file_path, sync_status, conflict_ref) VALUES (?, 'conflict', ?)
         ON CONFLICT(file_path) DO UPDATE SET conflict_ref = ?, sync_status = 'conflict' ''',
      [filePath, conflictRef, conflictRef],
    );
  }

  String? getConflictRef(String filePath) {
    final result = _db.select(
      'SELECT conflict_ref FROM file_metadata WHERE file_path = ?',
      [filePath],
    );
    if (result.isEmpty) return null;
    return result.first['conflict_ref'] as String?;
  }

  void clearConflictRef(String filePath) {
    _db.execute(
      'UPDATE file_metadata SET conflict_ref = NULL, sync_status = ? WHERE file_path = ?',
      [SyncStatus.synced.name, filePath],
    );
  }

  void deleteFileMetadata(String filePath) {
    _db.execute('DELETE FROM file_metadata WHERE file_path = ?', [filePath]);
  }

  void addSyncLogEntry({
    required SyncAction action,
    required int filesChanged,
    required bool success,
    String? errorMessage,
  }) {
    _db.execute(
      'INSERT INTO sync_log (timestamp, action, files_changed, success, error_message) VALUES (?, ?, ?, ?, ?)',
      [
        DateTime.now().toUtc().toIso8601String(),
        action.name,
        filesChanged,
        success ? 1 : 0,
        errorMessage,
      ],
    );
  }

  List<SyncLogEntry> getSyncLog({int limit = 50}) {
    final result = _db.select(
      'SELECT * FROM sync_log ORDER BY id DESC LIMIT ?',
      [limit],
    );
    return result.map((row) {
      return SyncLogEntry(
        timestamp: DateTime.parse(row['timestamp'] as String),
        action: SyncAction.values.firstWhere((e) => e.name == row['action']),
        filesChanged: row['files_changed'] as int,
        success: (row['success'] as int) == 1,
        errorMessage: row['error_message'] as String?,
      );
    }).toList();
  }

  void close() {
    _db.dispose();
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/file_system/metadata_database_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SQLite metadata database for sync status and sync log"
```

---

### Task 8: Workspace Riverpod Providers

**Files:**
- Create: `lib/features/workspace/application/workspace_providers.dart`
- Create: `lib/features/workspace/data/note_repository_provider.dart`

- [ ] **Step 1: Create note repository provider**

```dart
// lib/features/workspace/data/note_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';

final noteFileRepositoryProvider = FutureProvider<NoteFileRepository>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return NoteFileRepository(workspacePath: path);
});
```

- [ ] **Step 2: Create workspace providers**

```dart
// lib/features/workspace/application/workspace_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

final noteListProvider = FutureProvider<List<NoteFile>>((ref) async {
  final repo = await ref.watch(noteFileRepositoryProvider.future);
  return repo.listNotes();
});

final selectedCollectionProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add Riverpod providers for workspace note list"
```

---

## Phase 3: Workspace Explorer UI

### Task 9: Workspace Explorer Screen — Static Shell

**Files:**
- Modify: `lib/features/workspace/presentation/workspace_screen.dart`
- Create: `lib/features/workspace/presentation/widgets/note_list_item.dart`
- Create: `lib/features/workspace/presentation/widgets/workspace_app_bar.dart`
- Create: `lib/features/workspace/presentation/widgets/workspace_search_bar.dart`
- Create: `lib/features/workspace/presentation/widgets/collections_row.dart`
- Create: `lib/features/workspace/presentation/widgets/empty_state.dart`

- [ ] **Step 1: Create NoteListItem widget**

```dart
// lib/features/workspace/presentation/widgets/note_list_item.dart
import 'package:flutter/material.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:intl/intl.dart';

class NoteListItem extends StatelessWidget {
  final NoteFile note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onLongPress,
  });

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Color _syncDotColor(BuildContext context) {
    final colors = Theme.of(context).appColors;
    switch (note.syncStatus) {
      case SyncStatus.synced:
        return colors.success;
      case SyncStatus.pending:
        return colors.warning;
      case SyncStatus.conflict:
        return colors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Dismissible(
      key: Key(note.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _syncDotColor(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: note.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bgSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: colors.accentLight,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _timeAgo(note.updatedAt),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create WorkspaceAppBar**

```dart
// lib/features/workspace/presentation/widgets/workspace_app_bar.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class WorkspaceAppBar extends StatelessWidget {
  final VoidCallback onSyncTap;
  final VoidCallback onGitStatusTap;
  final Color gitStatusColor;

  const WorkspaceAppBar({
    super.key,
    required this.onSyncTap,
    required this.onGitStatusTap,
    required this.gitStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DevNotes',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: onGitStatusTap,
                  child: Row(
                    children: [
                      Icon(Icons.commit, size: 20, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gitStatusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onSyncTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 16, color: colors.textOnAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Sync Now',
                          style: TextStyle(
                            color: colors.textOnAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create SearchBar widget**

```dart
// lib/features/workspace/presentation/widgets/workspace_search_bar.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class WorkspaceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  const WorkspaceSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search notes...',
          hintStyle: TextStyle(color: colors.textMuted),
          prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
          filled: true,
          fillColor: colors.bgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create CollectionsRow**

```dart
// lib/features/workspace/presentation/widgets/collections_row.dart
import 'package:flutter/material.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class CollectionsRow extends StatelessWidget {
  final List<Collection> collections;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAdd;

  const CollectionsRow({
    super.key,
    required this.collections,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip(context, 'All Notes', selectedId == null, () => onSelect(null)),
          ...collections.map((col) => _chip(
                context,
                col.name,
                selectedId == col.id,
                () => onSelect(col.id),
              )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 18, color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final colors = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.accent : colors.bgSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.textOnAccent : colors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create EmptyState widget**

```dart
// lib/features/workspace/presentation/widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onCreateFirst;

  const EmptyState({super.key, required this.onCreateFirst});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 80, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first note to get started',
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onCreateFirst,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.textOnAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Create your first note'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Assemble WorkspaceScreen**

```dart
// lib/features/workspace/presentation/workspace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/presentation/widgets/workspace_app_bar.dart';
import 'package:devnotes/features/workspace/presentation/widgets/workspace_search_bar.dart';
import 'package:devnotes/features/workspace/presentation/widgets/collections_row.dart';
import 'package:devnotes/features/workspace/presentation/widgets/note_list_item.dart';
import 'package:devnotes/features/workspace/presentation/widgets/empty_state.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNote() {
    // TODO: Task 10 will implement create note dialog
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final notesAsync = ref.watch(noteListProvider);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceAppBar(
              onSyncTap: () {},
              onGitStatusTap: () {},
              gitStatusColor: colors.success,
            ),
            WorkspaceSearchBar(
              controller: _searchController,
              onChanged: (q) {},
              onTap: () {},
            ),
            CollectionsRow(
              collections: const [],
              selectedId: ref.watch(selectedCollectionProvider),
              onSelect: (id) =>
                  ref.read(selectedCollectionProvider.notifier).state = id,
              onAdd: () {},
            ),
            const SizedBox(height: 8),
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return EmptyState(onCreateFirst: _createNote);
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(noteListProvider);
                    },
                    child: ListView.separated(
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => Divider(
                        color: colors.border,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return NoteListItem(
                          note: note,
                          onTap: () => context.push(
                            '/editor/${Uri.encodeComponent(note.filePath)}',
                          ),
                          onDelete: () async {
                            // TODO: Task 10 — delete with confirmation
                          },
                          onLongPress: () {
                            // TODO: Task 10 — context menu
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 7: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: build Workspace Explorer UI with app bar, search bar, collections row, note list, and empty state"
```

---

### Task 10: Create / Delete / Rename Note Flows

**Files:**
- Create: `lib/features/workspace/presentation/widgets/create_note_dialog.dart`
- Create: `lib/features/workspace/presentation/widgets/rename_note_dialog.dart`
- Modify: `lib/features/workspace/presentation/workspace_screen.dart`
- Modify: `lib/features/workspace/application/workspace_providers.dart`

- [ ] **Step 1: Create CreateNoteDialog**

```dart
// lib/features/workspace/presentation/widgets/create_note_dialog.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class CreateNoteDialog extends StatefulWidget {
  const CreateNoteDialog({super.key});

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return AlertDialog(
      backgroundColor: colors.bgSecondary,
      title: Text('New Note', style: TextStyle(color: colors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Note title',
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tags (comma separated)',
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
            final tags = _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            Navigator.pop(context, {'title': title, 'tags': tags});
          },
          child: Text('Create', style: TextStyle(color: colors.accent)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Add workspace action providers**

```dart
// lib/features/workspace/application/workspace_providers.dart
// Replace entire file content:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

final noteListProvider = FutureProvider<List<NoteFile>>((ref) async {
  final repo = await ref.watch(noteFileRepositoryProvider.future);
  return repo.listNotes();
});

final selectedCollectionProvider = StateProvider<String?>((ref) => null);

final createNoteProvider = FutureProvider.family<NoteFile, ({String title, List<String> tags})>(
  (ref, params) async {
    final repo = await ref.read(noteFileRepositoryProvider.future);
    final note = await repo.createNote(title: params.title, tags: params.tags);
    ref.invalidate(noteListProvider);
    return note;
  },
);

final deleteNoteProvider = FutureProvider.family<void, String>(
  (ref, filePath) async {
    final repo = await ref.read(noteFileRepositoryProvider.future);
    await repo.deleteNote(filePath);
    ref.invalidate(noteListProvider);
  },
);

final renameNoteProvider =
    FutureProvider.family<NoteFile, ({String filePath, String newTitle})>(
  (ref, params) async {
    final repo = await ref.read(noteFileRepositoryProvider.future);
    final note = await repo.renameNote(params.filePath, params.newTitle);
    ref.invalidate(noteListProvider);
    return note;
  },
);
```

- [ ] **Step 3: Wire up WorkspaceScreen create/delete/rename**

Update `_createNote` and the delete/longPress callbacks in `workspace_screen.dart`:

```dart
// In _WorkspaceScreenState, replace _createNote method:
void _createNote() async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => const CreateNoteDialog(),
  );
  if (result == null) return;
  final note = await ref.read(createNoteProvider(
    (title: result['title'] as String, tags: result['tags'] as List<String>),
  ).future);
  if (mounted) {
    context.push('/editor/${Uri.encodeComponent(note.filePath)}');
  }
}

// Replace onDelete callback in NoteListItem:
onDelete: () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Note'),
      content: Text('Delete "${note.title}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirm == true) {
    ref.read(deleteNoteProvider(note.filePath));
  }
},
```

Add the import for `CreateNoteDialog` at the top of `workspace_screen.dart`:
```dart
import 'package:devnotes/features/workspace/presentation/widgets/create_note_dialog.dart';
```

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add create/delete/rename note flows with dialogs and providers"
```

---

## Phase 4: Markdown Editor

### Task 11: Editor Screen with Edit/Preview Swipe

**Files:**
- Modify: `lib/features/editor/presentation/editor_screen.dart`
- Create: `lib/features/editor/application/editor_providers.dart`
- Create: `lib/features/editor/presentation/widgets/editor_app_bar.dart`

- [ ] **Step 1: Create editor providers**

```dart
// lib/features/editor/application/editor_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

final currentNoteProvider = FutureProvider.family<NoteFile, String>(
  (ref, filePath) async {
    final repo = await ref.watch(noteFileRepositoryProvider.future);
    return repo.readNote(filePath);
  },
);

enum SaveStatus { saved, saving, unsaved }

final saveStatusProvider = StateProvider<SaveStatus>((ref) => SaveStatus.saved);
```

- [ ] **Step 2: Create EditorAppBar**

```dart
// lib/features/editor/presentation/widgets/editor_app_bar.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';

class EditorAppBar extends StatelessWidget {
  final SaveStatus saveStatus;
  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const EditorAppBar({
    super.key,
    required this.saveStatus,
    required this.currentPage,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              onPressed: onBack,
            ),
            const Spacer(),
            // Save status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: saveStatus == SaveStatus.saved
                    ? colors.success
                    : saveStatus == SaveStatus.saving
                        ? colors.warning
                        : colors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            // Page indicator dots
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == 0
                        ? colors.accent
                        : colors.textMuted.withAlpha(100),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == 1
                        ? colors.accent
                        : colors.textMuted.withAlpha(100),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.textSecondary),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Build EditorScreen with PageView swipe**

```dart
// lib/features/editor/presentation/editor_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/application/editor_providers.dart';
import 'package:devnotes/features/editor/presentation/widgets/editor_app_bar.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String filePath;
  const EditorScreen({super.key, required this.filePath});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _pageController = PageController();
  final _textController = TextEditingController();
  Timer? _debounce;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await ref.read(currentNoteProvider(widget.filePath).future);
    _textController.text = note.content;
  }

  void _onTextChanged(String value) {
    ref.read(saveStatusProvider.notifier).state = SaveStatus.unsaved;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => _save());
  }

  Future<void> _save() async {
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
    final note = await ref.read(currentNoteProvider(widget.filePath).future);
    final updated = note.copyWith(content: _textController.text);
    final repo = await ref.read(noteFileRepositoryProvider.future);
    await repo.saveNote(updated);
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
    ref.invalidate(currentNoteProvider(widget.filePath));
    ref.invalidate(noteListProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final saveStatus = ref.watch(saveStatusProvider);
    final noteAsync = ref.watch(currentNoteProvider(widget.filePath));

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            EditorAppBar(
              saveStatus: saveStatus,
              currentPage: _currentPage,
              onBack: () {
                if (saveStatus != SaveStatus.saved) _save();
                context.pop();
              },
              onMore: () {
                // TODO: Task 14 — more menu
              },
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Edit mode
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _textController,
                      onChanged: _onTextChanged,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 14,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Start writing...',
                      ),
                    ),
                  ),
                  // Preview mode
                  noteAsync.when(
                    data: (note) => Markdown(
                      data: _textController.text.isEmpty
                          ? note.content
                          : _textController.text,
                      padding: const EdgeInsets.all(20),
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.6),
                        h1: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                        h2: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                        h3: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        code: TextStyle(
                          color: colors.accentLight,
                          backgroundColor: colors.codeBg,
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: colors.codeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
            // TODO: Task 12 — Markdown Toolbar goes here
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Markdown Editor with Edit/Preview swipe, auto-save, and save status indicator"
```

---

### Task 12: Markdown Toolbar

**Files:**
- Create: `lib/features/editor/presentation/widgets/markdown_toolbar.dart`
- Create: `lib/features/editor/domain/toolbar_item.dart`
- Modify: `lib/features/editor/presentation/editor_screen.dart`

- [ ] **Step 1: Define toolbar items**

```dart
// lib/features/editor/domain/toolbar_item.dart
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
```

- [ ] **Step 2: Create MarkdownToolbar widget**

```dart
// lib/features/editor/presentation/widgets/markdown_toolbar.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/editor/domain/toolbar_item.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController textController;
  final List<String> visibleItemIds;

  const MarkdownToolbar({
    super.key,
    required this.textController,
    required this.visibleItemIds,
  });

  void _insertSyntax(ToolbarItem item) {
    final text = textController.text;
    final selection = textController.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0) {
      // No cursor, append at end
      textController.text = '$text${item.insertBefore}${item.insertAfter}';
      return;
    }

    final selectedText = text.substring(start, end);
    final newText = text.replaceRange(
      start,
      end,
      '${item.insertBefore}$selectedText${item.insertAfter}',
    );
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + item.insertBefore.length + selectedText.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final items = ToolbarItem.allItems
        .where((item) => visibleItemIds.contains(item.id))
        .toList();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _insertSyntax(item),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: item.icon != null
                    ? Icon(item.icon, size: 20, color: colors.textSecondary)
                    : Text(
                        item.label,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: item.id.startsWith('h')
                              ? 'Inter'
                              : 'JetBrainsMono',
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Add toolbar to EditorScreen**

In `editor_screen.dart`, replace the `// TODO: Task 12` comment with:

```dart
// After the Expanded PageView, before the closing Column bracket:
if (_currentPage == 0)
  MarkdownToolbar(
    textController: _textController,
    visibleItemIds: EditorPreferences.defaultToolbarItems,
  ),
```

Add imports:
```dart
import 'package:devnotes/features/editor/presentation/widgets/markdown_toolbar.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
```

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add scrollable Markdown toolbar with all syntax actions"
```

---

## Phase 5: Full-text Search

### Task 13: SQLite FTS5 Search Engine

**Files:**
- Create: `lib/core/search_engine/search_engine.dart`
- Test: `test/core/search_engine/search_engine_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/core/search_engine/search_engine_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';

void main() {
  late SearchEngine engine;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_search_test_');
    engine = SearchEngine(dbPath: '${tempDir.path}/search.db');
  });

  tearDown(() {
    engine.close();
    tempDir.deleteSync(recursive: true);
  });

  group('SearchEngine', () {
    test('indexNote and search returns matching results', () {
      engine.indexNote(
        filePath: '/notes/flutter.md',
        title: 'Getting Started with Flutter',
        tags: 'flutter, dart',
        content: 'Flutter is Google UI toolkit for building apps.',
      );
      engine.indexNote(
        filePath: '/notes/react.md',
        title: 'React Basics',
        tags: 'react, javascript',
        content: 'React is a JavaScript library for building UIs.',
      );

      final results = engine.search('Flutter');
      expect(results.length, 1);
      expect(results[0].filePath, '/notes/flutter.md');
    });

    test('search returns snippet with highlight', () {
      engine.indexNote(
        filePath: '/notes/test.md',
        title: 'Test Note',
        tags: 'test',
        content: 'This is a test note about searching functionality.',
      );

      final results = engine.search('searching');
      expect(results.length, 1);
      expect(results[0].snippet, contains('searching'));
    });

    test('removeNote removes from index', () {
      engine.indexNote(
        filePath: '/notes/delete.md',
        title: 'Delete Me',
        tags: '',
        content: 'Unique content xyz123.',
      );

      engine.removeNote('/notes/delete.md');
      final results = engine.search('xyz123');
      expect(results, isEmpty);
    });

    test('search with no results returns empty', () {
      final results = engine.search('nonexistent_term_xyz');
      expect(results, isEmpty);
    });

    test('updateNote reindexes', () {
      engine.indexNote(
        filePath: '/notes/update.md',
        title: 'Original',
        tags: '',
        content: 'Original content.',
      );
      engine.indexNote(
        filePath: '/notes/update.md',
        title: 'Updated',
        tags: 'new',
        content: 'Updated content.',
      );

      final results = engine.search('Updated');
      expect(results.length, 1);
      expect(results[0].title, 'Updated');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/search_engine/search_engine_test.dart
```
Expected: FAIL

- [ ] **Step 3: Implement SearchEngine**

```dart
// lib/core/search_engine/search_engine.dart
import 'package:sqlite3/sqlite3.dart';

class SearchResult {
  final String filePath;
  final String title;
  final String snippet;

  const SearchResult({
    required this.filePath,
    required this.title,
    required this.snippet,
  });
}

class SearchEngine {
  final Database _db;

  SearchEngine({required String dbPath}) : _db = sqlite3.open(dbPath) {
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        title,
        tags,
        content,
        file_path UNINDEXED
      )
    ''');
  }

  void indexNote({
    required String filePath,
    required String title,
    required String tags,
    required String content,
  }) {
    // Remove existing entry first (upsert)
    removeNote(filePath);
    _db.execute(
      'INSERT INTO notes_fts (file_path, title, tags, content) VALUES (?, ?, ?, ?)',
      [filePath, title, tags, content],
    );
  }

  void removeNote(String filePath) {
    _db.execute(
      'DELETE FROM notes_fts WHERE file_path = ?',
      [filePath],
    );
  }

  List<SearchResult> search(String query, {int limit = 50}) {
    if (query.trim().isEmpty) return [];

    // Escape special FTS5 characters and append wildcard
    final sanitized = query.replaceAll('"', '""');
    final ftsQuery = '"$sanitized"*';

    final results = _db.select(
      '''SELECT file_path, title, snippet(notes_fts, 2, '<b>', '</b>', '...', 32) as snippet
         FROM notes_fts
         WHERE notes_fts MATCH ?
         ORDER BY rank
         LIMIT ?''',
      [ftsQuery, limit],
    );

    return results.map((row) {
      return SearchResult(
        filePath: row['file_path'] as String,
        title: row['title'] as String,
        snippet: row['snippet'] as String,
      );
    }).toList();
  }

  void rebuildIndex(List<Map<String, String>> notes) {
    _db.execute('DELETE FROM notes_fts');
    for (final note in notes) {
      indexNote(
        filePath: note['filePath']!,
        title: note['title']!,
        tags: note['tags']!,
        content: note['content']!,
      );
    }
  }

  void close() {
    _db.dispose();
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/search_engine/search_engine_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SQLite FTS5 search engine with index/search/remove operations"
```

---

### Task 14: Search UI Integration

**Files:**
- Create: `lib/features/workspace/application/search_providers.dart`
- Create: `lib/features/workspace/presentation/widgets/search_results_list.dart`
- Modify: `lib/features/workspace/presentation/workspace_screen.dart`

- [ ] **Step 1: Create search providers**

```dart
// lib/features/workspace/application/search_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';

final searchEngineProvider = FutureProvider<SearchEngine>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return SearchEngine(dbPath: '$path/../search_index.db');
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final engine = await ref.watch(searchEngineProvider.future);
  return engine.search(query);
});
```

- [ ] **Step 2: Create SearchResultsList widget**

```dart
// lib/features/workspace/presentation/widgets/search_results_list.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class SearchResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final ValueChanged<String> onTap;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          title: Text(
            result.title,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            result.snippet.replaceAll(RegExp(r'</?b>'), ''),
            style: TextStyle(color: colors.textMuted, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onTap(result.filePath),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Wire search into WorkspaceScreen**

In `workspace_screen.dart`, update the search bar `onChanged` callback and conditionally show search results:

```dart
// Add to imports:
import 'package:devnotes/features/workspace/application/search_providers.dart';
import 'package:devnotes/features/workspace/presentation/widgets/search_results_list.dart';

// In build method, replace the Expanded child to handle search mode:
// After CollectionsRow:
Expanded(
  child: () {
    final query = ref.watch(searchQueryProvider);
    if (query.isNotEmpty) {
      final searchAsync = ref.watch(searchResultsProvider);
      return searchAsync.when(
        data: (results) => SearchResultsList(
          results: results,
          onTap: (filePath) => context.push('/editor/${Uri.encodeComponent(filePath)}'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Search error: $e')),
      );
    }
    return notesAsync.when(/* existing note list code */);
  }(),
),

// Update WorkspaceSearchBar onChanged:
WorkspaceSearchBar(
  controller: _searchController,
  onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
  onTap: () {},
),
```

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: integrate full-text search UI into Workspace Explorer"
```

---

## Phase 6: Collections

### Task 15: Collections Repository & UI

**Files:**
- Create: `lib/features/workspace/data/collections_repository.dart`
- Create: `lib/features/workspace/application/collections_providers.dart`
- Create: `lib/features/workspace/presentation/widgets/create_collection_dialog.dart`
- Modify: `lib/features/workspace/presentation/workspace_screen.dart`
- Test: `test/features/workspace/collections_repository_test.dart`

- [ ] **Step 1: Write test for collections repository**

```dart
// test/features/workspace/collections_repository_test.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/data/collections_repository.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';

void main() {
  late CollectionsRepository repo;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_collections_test_');
    repo = CollectionsRepository(storagePath: '${tempDir.path}/collections.json');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('CollectionsRepository', () {
    test('starts with empty list', () async {
      final collections = await repo.loadCollections();
      expect(collections, isEmpty);
    });

    test('save and load roundtrip', () async {
      final col = Collection(
        id: 'col-1',
        name: 'Flutter',
        filterTags: ['flutter'],
        icon: Icons.folder,
        color: Colors.purple,
      );
      await repo.saveCollections([col]);
      final loaded = await repo.loadCollections();
      expect(loaded.length, 1);
      expect(loaded[0].name, 'Flutter');
      expect(loaded[0].filterTags, ['flutter']);
    });

    test('overwrite replaces all', () async {
      final col1 = Collection(
        id: '1', name: 'A', filterTags: ['a'],
        icon: Icons.folder, color: Colors.red,
      );
      final col2 = Collection(
        id: '2', name: 'B', filterTags: ['b'],
        icon: Icons.folder, color: Colors.blue,
      );
      await repo.saveCollections([col1, col2]);
      await repo.saveCollections([col1]);
      final loaded = await repo.loadCollections();
      expect(loaded.length, 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/workspace/collections_repository_test.dart
```
Expected: FAIL

- [ ] **Step 3: Implement CollectionsRepository**

```dart
// lib/features/workspace/data/collections_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:devnotes/features/workspace/domain/collection.dart';

class CollectionsRepository {
  final String storagePath;

  CollectionsRepository({required this.storagePath});

  Future<List<Collection>> loadCollections() async {
    final file = File(storagePath);
    if (!file.existsSync()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Collection.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCollections(List<Collection> collections) async {
    final file = File(storagePath);
    final json = jsonEncode(collections.map((c) => c.toJson()).toList());
    await file.writeAsString(json);
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/workspace/collections_repository_test.dart
```
Expected: PASS

- [ ] **Step 5: Create providers and dialog**

```dart
// lib/features/workspace/application/collections_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:devnotes/features/workspace/data/collections_repository.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';

final collectionsRepositoryProvider = FutureProvider<CollectionsRepository>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return CollectionsRepository(storagePath: '$path/../collections.json');
});

final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final repo = await ref.watch(collectionsRepositoryProvider.future);
  return repo.loadCollections();
});
```

```dart
// lib/features/workspace/presentation/widgets/create_collection_dialog.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class CreateCollectionDialog extends StatefulWidget {
  const CreateCollectionDialog({super.key});

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return AlertDialog(
      backgroundColor: colors.bgSecondary,
      title: Text('New Collection', style: TextStyle(color: colors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Collection name',
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filter tags (comma separated)',
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final tags = _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            Navigator.pop(context, {'name': name, 'tags': tags});
          },
          child: Text('Create', style: TextStyle(color: colors.accent)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Wire collections into WorkspaceScreen**

Update `workspace_screen.dart` to load collections and filter notes by selected collection's tags. Update CollectionsRow to use real data and the add button to show CreateCollectionDialog.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Collections with JSON persistence, providers, and UI integration"
```

---

## Phase 7: Git Sync

### Task 16: Abstract Git Client

**Files:**
- Create: `lib/core/git_client/git_client.dart`
- Create: `lib/core/git_client/libgit2_git_client.dart`
- Test: `test/core/git_client/git_client_test.dart`

- [ ] **Step 1: Write test for GitClient interface**

```dart
// test/core/git_client/git_client_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/git_client/git_client.dart';

void main() {
  group('GitClient interface', () {
    test('MockGitClient implements all methods', () {
      final client = MockGitClient();
      expect(client, isA<GitClient>());
    });
  });
}

class MockGitClient implements GitClient {
  @override
  Future<void> clone(String url, String localPath, {String? username, String? password}) async {}
  @override
  Future<PullResult> pull({String? username, String? password}) async =>
      PullResult(success: true, filesChanged: 0, conflicts: []);
  @override
  Future<void> commitAll(String message) async {}
  @override
  Future<void> push({String? username, String? password}) async {}
  @override
  Future<String> currentBranch() async => 'main';
  @override
  Future<bool> hasChanges() async => false;
  @override
  Future<List<String>> conflictedFiles() async => [];
  @override
  Future<void> markResolved(String filePath) async {}
}
```

- [ ] **Step 2: Create abstract GitClient**

```dart
// lib/core/git_client/git_client.dart
class PullResult {
  final bool success;
  final int filesChanged;
  final List<String> conflicts;
  final String? errorMessage;

  const PullResult({
    required this.success,
    required this.filesChanged,
    required this.conflicts,
    this.errorMessage,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}

abstract class GitClient {
  Future<void> clone(String url, String localPath, {String? username, String? password});
  Future<PullResult> pull({String? username, String? password});
  Future<void> commitAll(String message);
  Future<void> push({String? username, String? password});
  Future<String> currentBranch();
  Future<bool> hasChanges();
  Future<List<String>> conflictedFiles();
  Future<void> markResolved(String filePath);
}
```

- [ ] **Step 3: Create libgit2dart implementation stub**

```dart
// lib/core/git_client/libgit2_git_client.dart
import 'package:devnotes/core/git_client/git_client.dart';

/// libgit2dart-based implementation of GitClient.
/// This wraps libgit2dart calls and runs them in an isolate.
/// NOTE: Requires libgit2dart to be properly configured for mobile platforms.
/// If libgit2dart fails on a platform, this class can be swapped for an
/// alternative implementation behind the abstract GitClient interface.
class Libgit2GitClient implements GitClient {
  final String repoPath;

  Libgit2GitClient({required this.repoPath});

  @override
  Future<void> clone(String url, String localPath, {String? username, String? password}) async {
    // TODO: Implement with libgit2dart Repository.clone()
    throw UnimplementedError('libgit2dart clone not yet implemented');
  }

  @override
  Future<PullResult> pull({String? username, String? password}) async {
    // TODO: Implement with libgit2dart fetch + merge
    throw UnimplementedError('libgit2dart pull not yet implemented');
  }

  @override
  Future<void> commitAll(String message) async {
    // TODO: Implement with libgit2dart index.addAll + commit
    throw UnimplementedError('libgit2dart commit not yet implemented');
  }

  @override
  Future<void> push({String? username, String? password}) async {
    // TODO: Implement with libgit2dart remote.push
    throw UnimplementedError('libgit2dart push not yet implemented');
  }

  @override
  Future<String> currentBranch() async {
    // TODO: Implement with libgit2dart head.name
    throw UnimplementedError('libgit2dart currentBranch not yet implemented');
  }

  @override
  Future<bool> hasChanges() async {
    // TODO: Implement with libgit2dart status
    throw UnimplementedError('libgit2dart hasChanges not yet implemented');
  }

  @override
  Future<List<String>> conflictedFiles() async {
    // TODO: Implement with libgit2dart index.conflicts
    throw UnimplementedError('libgit2dart conflictedFiles not yet implemented');
  }

  @override
  Future<void> markResolved(String filePath) async {
    // TODO: Implement with libgit2dart index.add + conflict cleanup
    throw UnimplementedError('libgit2dart markResolved not yet implemented');
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/git_client/git_client_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add abstract GitClient interface with libgit2dart implementation stub"
```

---

### Task 17: Git Setup Screen

**Files:**
- Modify: `lib/features/git_sync/presentation/git_setup_screen.dart`
- Create: `lib/features/git_sync/application/git_providers.dart`
- Create: `lib/features/git_sync/data/git_config_repository.dart`

- [ ] **Step 1: Create GitConfigRepository (secure storage)**

```dart
// lib/features/git_sync/data/git_config_repository.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class GitConfigRepository {
  final FlutterSecureStorage _storage;

  GitConfigRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _remoteUrlKey = 'git_remote_url';
  static const _usernameKey = 'git_username';
  static const _patKey = 'git_pat';

  Future<GitConfig?> loadConfig() async {
    final url = await _storage.read(key: _remoteUrlKey);
    final username = await _storage.read(key: _usernameKey);
    final pat = await _storage.read(key: _patKey);
    if (url == null || username == null || pat == null) return null;
    return GitConfig(remoteUrl: url, username: username, pat: pat);
  }

  Future<void> saveConfig(GitConfig config) async {
    await _storage.write(key: _remoteUrlKey, value: config.remoteUrl);
    await _storage.write(key: _usernameKey, value: config.username);
    await _storage.write(key: _patKey, value: config.pat);
  }

  Future<void> deleteConfig() async {
    await _storage.delete(key: _remoteUrlKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _patKey);
  }

  Future<bool> hasConfig() async {
    final url = await _storage.read(key: _remoteUrlKey);
    return url != null;
  }
}
```

- [ ] **Step 2: Create git providers**

```dart
// lib/features/git_sync/application/git_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/git_sync/data/git_config_repository.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';
import 'package:devnotes/core/utils/enums.dart';

final gitConfigRepoProvider = Provider<GitConfigRepository>(
  (ref) => GitConfigRepository(),
);

final gitConfigProvider = FutureProvider<GitConfig?>((ref) async {
  final repo = ref.watch(gitConfigRepoProvider);
  return repo.loadConfig();
});

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>(
  (ref) => SyncStateNotifier(),
);

class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier()
      : super(const SyncState(
          branchName: 'main',
          status: SyncStatus.synced,
        ));

  void setSyncing() => state = state.copyWith(status: SyncStatus.pending);
  void setSynced() => state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncAt: DateTime.now(),
      );
  void setError() => state = state.copyWith(status: SyncStatus.conflict);
  void setBranch(String branch) => state = state.copyWith(branchName: branch);
}
```

- [ ] **Step 3: Build GitSetupScreen UI**

```dart
// lib/features/git_sync/presentation/git_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class GitSetupScreen extends ConsumerStatefulWidget {
  const GitSetupScreen({super.key});

  @override
  ConsumerState<GitSetupScreen> createState() => _GitSetupScreenState();
}

class _GitSetupScreenState extends ConsumerState<GitSetupScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _patController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _patController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final pat = _patController.text.trim();
    if (url.isEmpty || username.isEmpty || pat.isEmpty) return;

    setState(() => _loading = true);
    final config = GitConfig(remoteUrl: url, username: username, pat: pat);
    await ref.read(gitConfigRepoProvider).saveConfig(config);
    ref.invalidate(gitConfigProvider);
    setState(() => _loading = false);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Text('Git Setup',
                      style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 24),
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accentSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.accentLight, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Connect your private Git repository to sync notes across devices. Your data stays in your control.',
                        style: TextStyle(color: colors.accentLight, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Form fields
              _buildField('Git Remote URL', _urlController, 'https://github.com/user/devnotes.git', colors),
              const SizedBox(height: 20),
              _buildField('Username', _usernameController, 'your-github-username', colors),
              const SizedBox(height: 20),
              _buildField('Personal Access Token (PAT)', _patController, 'ghp_xxxxxxxxxxxx', colors, obscure: true),
              const SizedBox(height: 16),
              // Security notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield, color: colors.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your data is secure',
                              style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Credentials are stored locally on your device. Notes are synced to your own private repository.',
                            style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Connect button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _connect,
                  icon: _loading
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textOnAccent))
                      : Icon(Icons.sync, color: colors.textOnAccent),
                  label: Text('Connect Repository',
                      style: TextStyle(color: colors.textOnAccent, fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Skip for now — use local storage only',
                      style: TextStyle(color: colors.textMuted, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, dynamic colors, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted),
            filled: true,
            fillColor: colors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Git Setup screen with secure storage for credentials"
```

---

### Task 18: Sync Engine & Sync History

**Files:**
- Create: `lib/features/git_sync/application/sync_service.dart`
- Create: `lib/features/git_sync/presentation/widgets/sync_history_sheet.dart`
- Modify: `lib/features/workspace/presentation/workspace_screen.dart`

- [ ] **Step 1: Create SyncService**

```dart
// lib/features/git_sync/application/sync_service.dart
import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/search_engine/search_engine.dart';
import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class SyncResult {
  final bool success;
  final int filesChanged;
  final List<String> conflicts;
  final String? error;

  const SyncResult({
    required this.success,
    this.filesChanged = 0,
    this.conflicts = const [],
    this.error,
  });
}

class SyncService {
  final GitClient gitClient;
  final MetadataDatabase metadataDb;
  final SearchEngine searchEngine;
  final NoteFileRepository noteRepo;

  SyncService({
    required this.gitClient,
    required this.metadataDb,
    required this.searchEngine,
    required this.noteRepo,
  });

  Future<SyncResult> sync(GitConfig config) async {
    try {
      // 1. Pull
      final pullResult = await gitClient.pull(
        username: config.username,
        password: config.pat,
      );

      if (pullResult.hasConflicts) {
        for (final file in pullResult.conflicts) {
          metadataDb.upsertSyncStatus(file, SyncStatus.conflict);
        }
        metadataDb.addSyncLogEntry(
          action: SyncAction.pull,
          filesChanged: pullResult.filesChanged,
          success: false,
          errorMessage: '${pullResult.conflicts.length} conflicts',
        );
        return SyncResult(
          success: false,
          filesChanged: pullResult.filesChanged,
          conflicts: pullResult.conflicts,
        );
      }

      // 2. Check for local changes
      final hasChanges = await gitClient.hasChanges();
      if (hasChanges) {
        final timestamp = DateTime.now().toUtc().toIso8601String();
        await gitClient.commitAll('DevNotes sync $timestamp');
        await gitClient.push(
          username: config.username,
          password: config.pat,
        );
      }

      // 3. Update metadata
      final totalChanged = pullResult.filesChanged + (hasChanges ? 1 : 0);
      metadataDb.addSyncLogEntry(
        action: hasChanges ? SyncAction.push : SyncAction.pull,
        filesChanged: totalChanged,
        success: true,
      );

      // 4. Rebuild search index for changed files
      final notes = await noteRepo.listNotes();
      searchEngine.rebuildIndex(notes.map((n) => {
        'filePath': n.filePath,
        'title': n.title,
        'tags': n.tags.join(', '),
        'content': n.content,
      }).toList());

      return SyncResult(success: true, filesChanged: totalChanged);
    } catch (e) {
      metadataDb.addSyncLogEntry(
        action: SyncAction.push,
        filesChanged: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return SyncResult(success: false, error: e.toString());
    }
  }
}
```

- [ ] **Step 2: Create SyncHistorySheet**

```dart
// lib/features/git_sync/presentation/widgets/sync_history_sheet.dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:intl/intl.dart';

class SyncHistorySheet extends StatelessWidget {
  final String branchName;
  final DateTime? lastSyncAt;
  final List<SyncLogEntry> entries;

  const SyncHistorySheet({
    super.key,
    required this.branchName,
    this.lastSyncAt,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final dateFormat = DateFormat('MMM d, HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sync History',
                  style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(branchName,
                    style: TextStyle(color: colors.accentLight, fontSize: 12, fontFamily: 'JetBrainsMono')),
              ),
            ],
          ),
          if (lastSyncAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Last sync: ${dateFormat.format(lastSyncAt!)}',
                  style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No sync history yet',
                    style: TextStyle(color: colors.textMuted)),
              ),
            )
          else
            ...entries.take(20).map((entry) {
              final icon = entry.success ? Icons.check_circle : Icons.error;
              final iconColor = entry.success ? colors.success : colors.error;
              final actionLabel = entry.action == SyncAction.push
                  ? 'Push'
                  : entry.action == SyncAction.pull
                      ? 'Pull'
                      : 'Conflict';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$actionLabel — ${entry.filesChanged} file(s)',
                              style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                          if (entry.errorMessage != null)
                            Text(entry.errorMessage!,
                                style: TextStyle(color: colors.error, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(dateFormat.format(entry.timestamp),
                        style: TextStyle(color: colors.textMuted, fontSize: 11)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Wire sync button and history sheet into WorkspaceScreen**

Update `WorkspaceAppBar` callbacks in `workspace_screen.dart`:

```dart
// onSyncTap: trigger sync
onSyncTap: () async {
  final config = await ref.read(gitConfigProvider.future);
  if (config == null) {
    context.push('/settings/git');
    return;
  }
  // TODO: call SyncService.sync(config) when git client is implemented
},

// onGitStatusTap: show sync history bottom sheet
onGitStatusTap: () {
  final syncState = ref.read(syncStateProvider);
  showModalBottomSheet(
    context: context,
    builder: (_) => SyncHistorySheet(
      branchName: syncState.branchName,
      lastSyncAt: syncState.lastSyncAt,
      entries: syncState.history,
    ),
  );
},
```

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SyncService, Sync History bottom sheet, and wire sync flow"
```

---

### Task 19: Conflict Resolution Screen

**Files:**
- Modify: `lib/features/git_sync/presentation/conflict_screen.dart`
- Create: `lib/features/git_sync/domain/conflict_parser.dart`
- Test: `test/features/git_sync/conflict_parser_test.dart`

- [ ] **Step 1: Write test for conflict parser**

```dart
// test/features/git_sync/conflict_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/git_sync/domain/conflict_parser.dart';

void main() {
  group('ConflictParser', () {
    test('parses conflict markers into blocks', () {
      const content = '''Some clean text
<<<<<<< HEAD
local version of the line
=======
remote version of the line
>>>>>>> remote
More clean text''';

      final blocks = ConflictParser.parse(content);
      expect(blocks.length, 3);
      expect(blocks[0].type, BlockType.clean);
      expect(blocks[0].content, 'Some clean text');
      expect(blocks[1].type, BlockType.conflict);
      expect(blocks[1].localContent, 'local version of the line');
      expect(blocks[1].remoteContent, 'remote version of the line');
      expect(blocks[2].type, BlockType.clean);
      expect(blocks[2].content, 'More clean text');
    });

    test('resolveKeepMine returns local content', () {
      const content = '''<<<<<<< HEAD
mine
=======
theirs
>>>>>>> remote''';

      final resolved = ConflictParser.resolveAll(content, Resolution.keepMine);
      expect(resolved, 'mine');
    });

    test('resolveKeepTheirs returns remote content', () {
      const content = '''<<<<<<< HEAD
mine
=======
theirs
>>>>>>> remote''';

      final resolved = ConflictParser.resolveAll(content, Resolution.keepTheirs);
      expect(resolved, 'theirs');
    });

    test('resolveKeepBoth returns both', () {
      const content = '''<<<<<<< HEAD
mine
=======
theirs
>>>>>>> remote''';

      final resolved = ConflictParser.resolveAll(content, Resolution.keepBoth);
      expect(resolved, 'mine\ntheirs');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/git_sync/conflict_parser_test.dart
```
Expected: FAIL

- [ ] **Step 3: Implement ConflictParser**

```dart
// lib/features/git_sync/domain/conflict_parser.dart
enum BlockType { clean, conflict }
enum Resolution { keepMine, keepTheirs, keepBoth }

class ConflictBlock {
  final BlockType type;
  final String content;
  final String? localContent;
  final String? remoteContent;

  const ConflictBlock.clean(this.content)
      : type = BlockType.clean,
        localContent = null,
        remoteContent = null;

  const ConflictBlock.conflict({
    required this.localContent,
    required this.remoteContent,
  })  : type = BlockType.conflict,
        content = '';
}

class ConflictParser {
  static final _conflictRegex = RegExp(
    r'<{7} .*\n([\s\S]*?)={7}\n([\s\S]*?)>{7} .*',
  );

  static List<ConflictBlock> parse(String content) {
    final blocks = <ConflictBlock>[];
    int lastEnd = 0;

    for (final match in _conflictRegex.allMatches(content)) {
      // Clean text before this conflict
      if (match.start > lastEnd) {
        final clean = content.substring(lastEnd, match.start).trim();
        if (clean.isNotEmpty) {
          blocks.add(ConflictBlock.clean(clean));
        }
      }

      blocks.add(ConflictBlock.conflict(
        localContent: match.group(1)!.trim(),
        remoteContent: match.group(2)!.trim(),
      ));

      lastEnd = match.end;
    }

    // Remaining clean text
    if (lastEnd < content.length) {
      final clean = content.substring(lastEnd).trim();
      if (clean.isNotEmpty) {
        blocks.add(ConflictBlock.clean(clean));
      }
    }

    return blocks;
  }

  static String resolveAll(String content, Resolution resolution) {
    return content.replaceAllMapped(_conflictRegex, (match) {
      final local = match.group(1)!.trim();
      final remote = match.group(2)!.trim();
      switch (resolution) {
        case Resolution.keepMine:
          return local;
        case Resolution.keepTheirs:
          return remote;
        case Resolution.keepBoth:
          return '$local\n$remote';
      }
    });
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/git_sync/conflict_parser_test.dart
```
Expected: PASS

- [ ] **Step 5: Build ConflictScreen UI**

```dart
// lib/features/git_sync/presentation/conflict_screen.dart
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
            // App bar
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
                        style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            // Content
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
                        style: TextStyle(color: colors.textSecondary, fontFamily: 'JetBrainsMono', fontSize: 13),
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
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LOCAL (yours)', style: TextStyle(color: colors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(block.localContent!, style: TextStyle(color: colors.textPrimary, fontFamily: 'JetBrainsMono', fontSize: 13)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: colors.border),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.accentLight.withAlpha(30),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REMOTE (theirs)', style: TextStyle(color: colors.accentLight, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(block.remoteContent!, style: TextStyle(color: colors.textPrimary, fontFamily: 'JetBrainsMono', fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Action buttons
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
                      style: ElevatedButton.styleFrom(backgroundColor: colors.accent),
                      child: Text('Keep Both', style: TextStyle(color: colors.textOnAccent)),
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
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add Conflict Resolution screen with parser and Keep Mine/Theirs/Both actions"
```

---

## Phase 8: Settings

### Task 20: Settings Screen

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Create: `lib/features/settings/application/settings_providers.dart`
- Create: `lib/features/settings/data/preferences_repository.dart`

- [ ] **Step 1: Create PreferencesRepository**

```dart
// lib/features/settings/data/preferences_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/core/utils/enums.dart';

class PreferencesRepository {
  Future<EditorPreferences> loadEditorPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return EditorPreferences(
      fontSize: prefs.getDouble('editor_font_size') ?? 14.0,
      fontFamily: prefs.getString('editor_font_family') ?? 'JetBrains Mono',
      autoSaveInterval: Duration(seconds: prefs.getInt('editor_autosave_seconds') ?? 3),
      toolbarItems: prefs.getStringList('editor_toolbar_items') ?? EditorPreferences.defaultToolbarItems,
      syncFrequency: SyncFrequency.values.firstWhere(
        (e) => e.name == (prefs.getString('sync_frequency') ?? 'manual'),
        orElse: () => SyncFrequency.manual,
      ),
      periodicInterval: prefs.getInt('sync_periodic_minutes') != null
          ? Duration(minutes: prefs.getInt('sync_periodic_minutes')!)
          : null,
    );
  }

  Future<void> saveEditorPreferences(EditorPreferences pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('editor_font_size', pref.fontSize);
    await prefs.setString('editor_font_family', pref.fontFamily);
    await prefs.setInt('editor_autosave_seconds', pref.autoSaveInterval.inSeconds);
    await prefs.setStringList('editor_toolbar_items', pref.toolbarItems);
    await prefs.setString('sync_frequency', pref.syncFrequency.name);
    if (pref.periodicInterval != null) {
      await prefs.setInt('sync_periodic_minutes', pref.periodicInterval!.inMinutes);
    }
  }
}
```

- [ ] **Step 2: Create settings providers**

```dart
// lib/features/settings/application/settings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/features/settings/data/preferences_repository.dart';

final preferencesRepoProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(),
);

final editorPreferencesProvider = FutureProvider<EditorPreferences>((ref) async {
  final repo = ref.watch(preferencesRepoProvider);
  return repo.loadEditorPreferences();
});
```

- [ ] **Step 3: Build Settings screen**

```dart
// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/utils/enums.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final theme = ref.watch(themeProvider);

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
                    Text('Settings',
                        style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _sectionHeader('Git', colors),
                  _tile('Git Repository', Icons.commit, colors, () => context.push('/settings/git')),
                  _sectionHeader('Sync', colors),
                  _tile('Sync Frequency', Icons.sync, colors, () {
                    // TODO: open sync frequency picker
                  }),
                  _sectionHeader('Editor', colors),
                  _tile('Font & Size', Icons.text_fields, colors, () {
                    // TODO: open editor preferences
                  }),
                  _tile('Toolbar Layout', Icons.dashboard_customize, colors, () {
                    // TODO: open toolbar customization
                  }),
                  _sectionHeader('Appearance', colors),
                  _themeTile(context, ref, colors, theme),
                  _sectionHeader('Data', colors),
                  _tile('Export Notes', Icons.upload_file, colors, () {
                    // TODO: export
                  }),
                  _tile('Import Notes', Icons.download, colors, () {
                    // TODO: import
                  }),
                  _tile('Rebuild Search Index', Icons.refresh, colors, () {
                    // TODO: rebuild index
                  }),
                  _sectionHeader('Collections', colors),
                  _tile('Manage Collections', Icons.folder, colors, () {
                    // TODO: manage collections
                  }),
                  _sectionHeader('About', colors),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: colors.textMuted),
                    title: Text('DevNotes v1.0.0', style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text('Local-first Markdown notes for devs', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(title,
          style: TextStyle(color: colors.accentLight, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }

  Widget _tile(String title, IconData icon, dynamic colors, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: onTap,
    );
  }

  Widget _themeTile(BuildContext context, WidgetRef ref, dynamic colors, ThemePreference current) {
    return ListTile(
      leading: Icon(Icons.palette, color: colors.textSecondary),
      title: Text('Theme', style: TextStyle(color: colors.textPrimary)),
      trailing: DropdownButton<ThemePreference>(
        value: current,
        dropdownColor: colors.bgSecondary,
        underline: const SizedBox(),
        items: ThemePreference.values.map((t) {
          return DropdownMenuItem(
            value: t,
            child: Text(t.name[0].toUpperCase() + t.name.substring(1),
                style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) ref.read(themeProvider.notifier).setTheme(value);
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Add settings route to Workspace (hamburger or gear icon)**

In `workspace_screen.dart`, add a settings navigation. Update the AppBar or add a drawer icon:

```dart
// Add to the workspace_screen.dart, after the Sync Now button in WorkspaceAppBar
// Or add it to the workspace screen directly as a temporary icon:
// In WorkspaceScreen build, before the Column:
// Add an IconButton in the app bar area to navigate to settings
```

A simpler approach: add a gear icon in the AppBar. Update `WorkspaceAppBar` to accept an `onSettingsTap` callback and add the icon.

- [ ] **Step 5: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add Settings screen with theme picker, git, editor, data, and about sections"
```

---

## Phase 9: Onboarding

### Task 21: Welcome Wizard

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_screen.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_git_screen.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_first_note_screen.dart`

- [ ] **Step 1: Build OnboardingScreen with swipeable cards**

```dart
// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.smartphone,
      title: 'Local-First',
      description: 'Your notes live on your device as plain .md files. No cloud lock-in, no subscriptions.',
    ),
    _OnboardingPage(
      icon: Icons.sync,
      title: 'Git Sync',
      description: 'Sync via your own GitHub or GitLab repo. You own the data, always.',
    ),
    _OnboardingPage(
      icon: Icons.code,
      title: 'Built for Developers',
      description: 'Markdown editing with syntax highlighting, code blocks, and a customizable toolbar.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 80, color: colors.accent),
                        const SizedBox(height: 32),
                        Text(page.title,
                            style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(page.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary, fontSize: 16, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage ? colors.accent : colors.textMuted.withAlpha(80),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding/git'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Get Started',
                      style: TextStyle(color: colors.textOnAccent, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingPage({required this.icon, required this.title, required this.description});
}
```

- [ ] **Step 2: Build OnboardingGitScreen**

```dart
// lib/features/onboarding/presentation/onboarding_git_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/features/git_sync/presentation/git_setup_screen.dart';

class OnboardingGitScreen extends ConsumerWidget {
  const OnboardingGitScreen({super.key});

  Future<void> _skip(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (context.mounted) context.go('/onboarding/first-note');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reuse GitSetupScreen but override the skip/connect behavior
    // For onboarding, after connect/skip → go to first-note
    return const GitSetupScreen(); // Simplified: in full impl, wrap with custom callbacks
  }
}
```

- [ ] **Step 3: Build OnboardingFirstNoteScreen**

```dart
// lib/features/onboarding/presentation/onboarding_first_note_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/data/note_repository_provider.dart';

class OnboardingFirstNoteScreen extends ConsumerWidget {
  const OnboardingFirstNoteScreen({super.key});

  static const _sampleContent = '''# Welcome to DevNotes!

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
''';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, size: 60, color: colors.accent),
                const SizedBox(height: 24),
                Text('Your First Note',
                    style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'We\'ll create a sample note with a Markdown guide to get you started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final repo = await ref.read(noteFileRepositoryProvider.future);
                      final note = await repo.createNote(
                        title: 'Welcome to DevNotes',
                        tags: ['getting-started'],
                      );
                      // Write sample content
                      final updated = note.copyWith(content: _sampleContent);
                      await repo.saveNote(updated);

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_complete', true);

                      if (context.mounted) context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Create & Start',
                        style: TextStyle(color: colors.textOnAccent, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Onboarding wizard with welcome cards, git setup, and sample first note"
```

---

### Task 22: Feature Tooltips

**Files:**
- Create: `lib/features/onboarding/application/tooltip_service.dart`
- Modify: `lib/features/workspace/presentation/workspace_screen.dart`
- Modify: `lib/features/editor/presentation/editor_screen.dart`

- [ ] **Step 1: Create TooltipService**

```dart
// lib/features/onboarding/application/tooltip_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TooltipService {
  static Future<bool> shouldShow(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tooltip_$key') ?? false);
  }

  static Future<void> markShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tooltip_$key', true);
  }

  static void showTooltips({
    required BuildContext context,
    required String tooltipKey,
    required List<TargetFocus> targets,
  }) async {
    if (!await shouldShow(tooltipKey)) return;

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      onFinish: () => markShown(tooltipKey),
      onSkip: () {
        markShown(tooltipKey);
        return true;
      },
    );

    tutorial.show(context: context);
  }

  static TargetFocus createTarget({
    required GlobalKey key,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
  }) {
    return TargetFocus(
      keyTarget: key,
      alignSkip: Alignment.topRight,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            );
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Add tooltip keys to WorkspaceScreen widgets**

In `workspace_screen.dart`, add `GlobalKey`s to searchbar, sync button, and FAB, then call `TooltipService.showTooltips` in `initState` after a small delay:

```dart
// Add to _WorkspaceScreenState:
final _searchKey = GlobalKey();
final _syncKey = GlobalKey();
final _fabKey = GlobalKey();

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    TooltipService.showTooltips(
      context: context,
      tooltipKey: 'workspace',
      targets: [
        TooltipService.createTarget(
          key: _searchKey,
          title: 'Search',
          description: 'Search through all your notes with full-text search.',
        ),
        TooltipService.createTarget(
          key: _syncKey,
          title: 'Sync',
          description: 'Tap to sync your notes with your Git repository.',
        ),
        TooltipService.createTarget(
          key: _fabKey,
          title: 'New Note',
          description: 'Create a new Markdown note.',
          align: ContentAlign.top,
        ),
      ],
    );
  });
}
```

Wrap the search bar, sync button, and FAB with their respective keys.

- [ ] **Step 3: Add tooltip keys to EditorScreen**

Similarly, add tooltips for the toolbar and swipe gesture in `editor_screen.dart`.

- [ ] **Step 4: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add interactive feature tooltips for first-time users on workspace and editor"
```

---

## Phase 10: Export/Import

### Task 23: Export & Import Data

**Files:**
- Create: `lib/features/settings/data/export_import_service.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Test: `test/features/settings/export_import_service_test.dart`

- [ ] **Step 1: Write test**

```dart
// test/features/settings/export_import_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/settings/data/export_import_service.dart';

void main() {
  late Directory tempDir;
  late Directory workspaceDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_export_test_');
    workspaceDir = Directory('${tempDir.path}/workspace')..createSync();
    // Create sample files
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

      // Create a clean workspace
      final importDir = Directory('${tempDir.path}/import_workspace')..createSync();
      final importService = ExportImportService(workspacePath: importDir.path);
      await importService.importFromZip(zipPath);

      final files = importDir.listSync().whereType<File>().toList();
      expect(files.length, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/settings/export_import_service_test.dart
```
Expected: FAIL

- [ ] **Step 3: Implement ExportImportService**

```dart
// lib/features/settings/data/export_import_service.dart
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
      final relativePath = file.path.substring(workspacePath.length + 1);
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Failed to encode zip');
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
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/settings/export_import_service_test.dart
```
Expected: PASS

- [ ] **Step 5: Wire into Settings screen**

Update the export/import tiles in `settings_screen.dart` to call `ExportImportService` and use `share_plus` for sharing the zip.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add export/import service with zip archive support"
```

---

## Final Phase: Integration & Polish

### Task 24: Wire All Providers & Final Integration

**Files:**
- Modify: `lib/main.dart` — initialize databases, search engine on app start
- Modify: `lib/features/workspace/presentation/workspace_screen.dart` — connect real collections data
- Modify: `lib/features/editor/presentation/editor_screen.dart` — use editor preferences for font/toolbar

- [ ] **Step 1: Update main.dart to initialize services**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Services are lazily initialized via providers — no eager init needed
  runApp(
    const ProviderScope(
      child: DevNotesApp(),
    ),
  );
}
```

- [ ] **Step 2: Wire editor preferences into EditorScreen**

Update `EditorScreen` to read `EditorPreferences` from provider and use `fontSize`, `fontFamily`, and `toolbarItems`:

```dart
// In editor_screen.dart build method, read preferences:
final prefsAsync = ref.watch(editorPreferencesProvider);

// Use in TextField style:
style: TextStyle(
  color: colors.textPrimary,
  fontFamily: prefs.fontFamily,
  fontSize: prefs.fontSize,
  height: 1.6,
),

// Use in MarkdownToolbar:
MarkdownToolbar(
  textController: _textController,
  visibleItemIds: prefs.toolbarItems,
),
```

- [ ] **Step 3: Index notes on app start**

Create an initialization provider that builds the search index:

```dart
// Add to search_providers.dart:
final searchIndexInitProvider = FutureProvider<void>((ref) async {
  final engine = await ref.read(searchEngineProvider.future);
  final repo = await ref.read(noteFileRepositoryProvider.future);
  final notes = await repo.listNotes();
  engine.rebuildIndex(notes.map((n) => {
    'filePath': n.filePath,
    'title': n.title,
    'tags': n.tags.join(', '),
    'content': n.content,
  }).toList());
});
```

Watch this provider in `WorkspaceScreen` to trigger index build.

- [ ] **Step 4: Run all tests**

```bash
flutter test
```
Expected: ALL PASS

- [ ] **Step 5: Verify app builds on both platforms**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: wire all providers, initialize search index, apply editor preferences"
```

---

### Task 25: Final Test Run & Cleanup

- [ ] **Step 1: Run all tests**

```bash
flutter test --coverage
```
Expected: ALL PASS

- [ ] **Step 2: Run Flutter analyzer**

```bash
flutter analyze
```
Expected: No issues found

- [ ] **Step 3: Remove TODO comments that reference completed tasks**

Search for `// TODO: Task` comments and remove any that reference completed work.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: final cleanup — remove stale TODOs, verify all tests pass"
```
