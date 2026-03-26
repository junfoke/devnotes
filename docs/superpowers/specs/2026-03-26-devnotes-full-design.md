# DevNotes — Full Vision Design Spec

## 1. Project Overview

- **App name:** DevNotes
- **Platform:** Mobile (Flutter, iOS & Android)
- **Purpose:** Local-first Markdown note-taking app for developers
- **Core USP:**
  - Local-first: 100% data on device as `.md` files, no backend/database
  - BYOC (Bring Your Own Cloud): sync via git commit/push to user's private GitHub/GitLab repo. Server cost = 0
  - Markdown rendering with code syntax highlighting

## 2. Architecture & Tech Stack

- **Framework:** Flutter (latest stable, strict null-safety)
- **Architecture:** Monolithic Feature-first
- **State Management:** `flutter_riverpod` (with `riverpod_generator`)
- **Routing:** `go_router`

### Core Packages

| Function | Package | Notes |
|---|---|---|
| File I/O | `path_provider` + `dart:io` | Read/write `.md` files |
| YAML Frontmatter | `yaml` + `yaml_writer` | Parse & serialize frontmatter |
| Git client | `libgit2dart` | Clone, pull, commit, push. Fallback: native git via method channel |
| Markdown render | `flutter_markdown` | Preview mode |
| Syntax highlight | `flutter_highlight` | Code blocks |
| Secure storage | `flutter_secure_storage` | Store PAT encrypted |
| Full-text search | `sqlite3_flutter_libs` + FTS5 | Full-text index, runs in isolate |
| Theme | `flex_color_scheme` or custom | Dark/Light/System |
| Onboarding tooltips | `tutorial_coach_mark` | Interactive first-time tooltips |

### Project Structure

```
lib/
  app/                → App widget, router config, theme
  features/
    workspace/        → Explorer, Search, Collections
      presentation/   → Screens, widgets
      application/    → Riverpod providers, controllers
      domain/         → Models (NoteFile, Collection, Tag)
      data/           → File system repository
    editor/           → Markdown edit, swipe Preview, Toolbar
      presentation/
      application/
      domain/
      data/
    git_sync/         → Setup, Sync engine, Conflict resolution
      presentation/
      application/
      domain/
      data/
    settings/         → Preferences, Theme, Export/Import
      presentation/
      application/
      domain/
      data/
    onboarding/       → Welcome wizard, Feature tooltips
      presentation/
      application/
  core/
    file_system/      → Base IO utilities
    git_client/       → libgit2dart wrapper (abstract GitClient)
    search_engine/    → SQLite FTS5 indexer (runs in isolate)
    theme/            → Color tokens, ThemeData definitions
    utils/            → Date formatting, string helpers
```

## 3. Data Structure & Models

### Note file format

Each note is a `.md` file with YAML frontmatter:

```yaml
---
title: "Note title"
tags: ["flutter", "idea"]
createdAt: "2026-03-26T10:00:00Z"
updatedAt: "2026-03-26T10:30:00Z"
---

# Markdown content here
```

**Note:** `syncStatus` and `conflictRef` are stored in a local SQLite metadata table, NOT in the `.md` file frontmatter. This avoids sync conflicts caused by status fields being committed to git.

### Core Models

```dart
class NoteFile {
  String filePath;
  String title;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  SyncStatus syncStatus;
  String? conflictRef;
  String content;           // raw markdown body
}

class Collection {
  String name;
  List<String> filterTags;  // notes match ANY of these tags
  IconData icon;
  Color color;
}

class SyncState {
  String branchName;
  SyncStatus status;        // idle | syncing | error
  DateTime? lastSyncAt;
  List<SyncLogEntry> history;
}

class SyncLogEntry {
  DateTime timestamp;
  SyncAction action;        // push | pull | conflict
  int filesChanged;
  bool success;
  String? errorMessage;
}

class GitConfig {
  String remoteUrl;
  String username;
  String pat;               // encrypted in secure storage
}

class EditorPreferences {
  double fontSize;
  String fontFamily;         // "JetBrains Mono", "Fira Code", etc.
  Duration autoSaveInterval; // default 3s debounce
  List<String> toolbarItems; // user-customized toolbar order
  SyncFrequency syncFrequency; // manual | onSave | periodic
  Duration? periodicInterval;
}

enum ThemePreference { dark, light, system }
```

### Search Index (SQLite FTS5)

```sql
CREATE VIRTUAL TABLE notes_fts USING fts5(
  title,
  tags,
  content,
  file_path UNINDEXED
);
```

- Index rebuild on app start (in isolate)
- Incremental update on save/delete
- Query supports: keyword search, tag filter, date range via separate metadata table

### Collections Storage

- Stored in local JSON file (`collections.json` in app directory, NOT committed to git)
- Each collection = name + filter tags list
- Predefined: "All Notes" (no filter), "Untagged" (notes with no tags)

## 4. Screens & Flows

### 4.1 Onboarding Flow

**Welcome Screen (`/onboarding`):**
- Illustration + "Welcome to DevNotes"
- 2-3 swipeable cards: Local-first, Git Sync, Markdown for Devs
- Button "Get Started"

**Git Setup (`/onboarding/git`):**
- Same UI as Git Setup screen
- Clear "Skip for now" option
- After connect or skip → create 1 sample note template

**First Note (`/onboarding/first-note`):**
- Opens editor with sample note (Markdown syntax guide)
- On save → navigate to Workspace Explorer

**Feature Tooltips:**
- First time on Workspace: highlight Search bar, Sync button, FAB, tag chips
- First time on Editor: highlight Toolbar, Edit/Preview swipe, auto-save indicator
- Each tooltip shown once only, dismiss on tap

### 4.2 Workspace Explorer (`/`)

**AppBar:**
- Left: "DevNotes"
- Right: Git status icon (color-coded by status) + "Sync Now" button
- Tap git status icon → open Sync History bottom sheet

**Search Bar (below AppBar):**
- Persistent search field, placeholder "Search notes..."
- On focus → show recent searches + filter chips (tags, date range, sync status)
- Full-text results with highlighted matched text snippet

**Collections Section (above note list):**
- Horizontal scrollable row of Collection chips
- "All Notes" selected by default
- "+" button to create new Collection (pick name + tags)
- Long press Collection → Edit/Delete

**Note List:**
- Each item: title, tag chips (tappable to filter), time ago, sync status dot
- Swipe left → Delete (with confirmation dialog)
- Long press → Context menu: Rename, Move to Collection, Delete, Share as `.md`
- Pull-to-refresh → trigger git pull

**FAB:** "+" button → dialog for title + optional tags → open Editor

**Empty State:** Illustration + "No notes yet" + "Create your first note" CTA

### 4.3 Markdown Editor (`/editor/:filePath`)

**AppBar:**
- Left: Back button
- Center: Auto-save indicator (small dot: green = saved, orange = saving)
- Right: More menu (three dots) → Rename, Tags, Share, Delete

**Edit/Preview:** Swipe left/right to switch. Animated page transition. Indicator dots below AppBar.

**Editor (Edit mode):**
- Full-screen text field, monospace font
- Syntax-aware: headings bold/larger, code blocks with different background

**Preview mode:**
- Rendered markdown with code syntax highlighting
- Scrollable, tap code block → copy to clipboard

**Toolbar (above keyboard):**
- Scrollable horizontal, optional 2 rows in Settings
- Default items: H1, H2, H3, Bold, Italic, Strikethrough, Link, Image, Code inline, Code block, Checklist, List (ordered/unordered), Quote, Table, Horizontal rule
- User customizable: hide/show, reorder in Settings

### 4.4 Git Setup (`/settings/git`)

- Same UI as current mockup
- After connected: screen becomes "Git Settings" with Disconnect button, view remote URL, change PAT

### 4.5 Sync History (bottom sheet)

- Opens from tapping git status icon on Workspace
- Header: branch name, last sync time
- List: each entry shows timestamp, action (push/pull/conflict), files changed count, status icon
- If conflict → red entry, tap → navigate to conflict file

### 4.6 Conflict Resolution (`/conflict/:filePath`)

- On pull with conflicts → notification banner on Workspace: "1 file has conflicts"
- Tap → open Conflict Editor
- Display file with inline markers `<<<< HEAD` / `>>>> remote`
- 3 buttons: "Keep Mine" / "Keep Theirs" / "Keep Both"
- Manual edit allowed before resolving
- After resolve → auto commit merge result

### 4.7 Settings (`/settings`)

| Section | Items |
|---|---|
| **Git** | Remote URL (read-only), Username, Change PAT, Disconnect repo |
| **Sync** | Frequency: Manual / On Save / Periodic (5/15/30 min) |
| **Editor** | Font size slider, Font family picker, Auto-save interval, Default toolbar layout (drag to reorder) |
| **Appearance** | Theme: Dark / Light / System |
| **Data** | Export all notes (.zip), Import notes, Rebuild search index |
| **Collections** | Manage Collections (edit name/tags/icon, delete) |
| **About** | Version, Licenses, GitHub link |

### Navigation Map

```
/onboarding → /onboarding/git → /onboarding/first-note → /
/ (Workspace Explorer)
  → /editor/:filePath
  → /settings
  → /settings/git
  → /settings/editor
  → /settings/sync
  → /settings/appearance
  → /settings/data
  → /settings/collections
  → /conflict/:filePath
  Sync History → bottom sheet (no route)
  Search → inline on Workspace
```

## 5. Key Technical Decisions

### 5.1 Git Operations & libgit2dart

**Risk:** `libgit2dart` is young, may have issues on iOS (sandboxing) and Android (native binary linking).

**Strategy:**
- Initial implementation with `libgit2dart`, wrapped in abstract `GitClient` class
- Fallback: `git` CLI binary bundle or Method Channel to native git library (iOS: `ObjectiveGit`, Android: `JGit`)
- All git operations run in dedicated **Isolate** to avoid blocking UI

**Git Sync Flow:**
1. User taps "Sync Now" (or auto trigger)
2. `git pull --rebase` (prefer rebase for clean history)
3. If conflict → mark files, show notification, STOP sync
4. If clean → `git add -A` → `git commit "DevNotes sync [timestamp]"` → `git push`
5. Update SyncState + SyncLogEntry
6. Rebuild search index for changed files

### 5.2 Conflict Detection & Resolution

```
Pull result → check for conflicted files
  → Parse conflict markers (<<<< / ==== / >>>>)
  → Split into local_content vs remote_content
  → Display in Conflict Editor
  → User chooses resolution
  → Write resolved file
  → git add resolved_file → git commit "Resolve conflict: filename.md"
```

### 5.3 Full-text Search (SQLite FTS5)

- **Index build:** On app start, scan all `.md` files → tokenize → insert into FTS5 table. Runs in isolate.
- **Incremental update:** On save/delete → update only that record.
- **Query:** FTS5 `MATCH` syntax. Results use `snippet()` function for highlighting.
- **Performance:** FTS5 handles 10,000+ documents well. Index file in app's internal storage, not committed to git.

### 5.4 Auto-save

```
User typing → debounce 3s (configurable) → save file to disk
  → Update YAML frontmatter (updatedAt)
  → Update search index (incremental)
  → Set syncStatus = "pending"
  → If sync mode = "onSave" → trigger sync
```

### 5.5 Theme System

- `ThemeData` with 2 color token sets (dark/light) matching current design variables (`$--bg-primary`, `$--accent`, etc.)
- `ThemePreference` stored in `SharedPreferences`
- `system` mode: listen to `MediaQuery.platformBrightnessOf(context)`
- Riverpod `themeProvider` supplies `ThemeData` to `MaterialApp`

### 5.6 Toolbar Customization

- Default toolbar items list stored in `EditorPreferences`
- Settings screen: drag-to-reorder list with toggle on/off per item
- Custom order saved to `SharedPreferences` as `List<String>` (item IDs)
- Editor reads from provider, renders toolbar accordingly

### 5.7 Export/Import

- **Export:** Zip entire workspace folder → share via system share sheet
- **Import:** Accept `.zip` or folder with `.md` files → copy to workspace → rebuild index

## 6. Design System

- **Theme:** Dark mode default, Light mode available, System follow option
- **Background:** Dark Navy/Black (`$--bg-primary`)
- **Accent:** Purple (`$--accent`)
- **Body font:** Inter/Roboto/San Francisco
- **Code font:** JetBrains Mono / Fira Code (configurable)
- **Status colors:** Green = synced/success, Orange = pending/saving, Red = error/conflict
