# DevNotes

Local-first Markdown note-taking app for developers, built with Flutter.

Your notes live on your device as plain `.md` files. Sync to your own private Git repository — no cloud lock-in, no subscriptions. You own the data, always.

## Features

### Markdown Editor
- Edit/Preview swipe between raw Markdown and rendered preview
- Auto-save with 3-second debounce after each keystroke
- Save status indicator (green = saved, yellow = saving, gray = unsaved)
- Scrollable toolbar with 16 Markdown syntax actions (headings, bold, italic, strikethrough, links, images, inline/block code, checklists, lists, quotes, tables, horizontal rules)
- Monospace font (JetBrains Mono or Fira Code) with configurable size
- Preview with syntax-highlighted code blocks, tappable links and checklists
- Edit tags, share, view info or delete a note from the editor menu
- Never overwrites a note that changed on disk while you were editing (e.g. after a sync)

### Workspace Explorer
- Note list sorted by last updated
- Collections with tag-based filtering
- Create, rename, delete notes with dialogs
- Swipe-to-delete with confirmation
- Context menu (long press) for rename/delete

### Full-Text Search
- SQLite FTS5 search engine
- Search across titles, tags, and note content
- Debounced input (300ms) for smooth UX
- Snippet preview in results

### Git Sync (Android)
- BYOC (Bring Your Own Cloud) — sync to your private GitHub/GitLab repo
- HTTPS authentication with Personal Access Token
- Smart Init: auto-detects empty vs existing remote repos
- Pull/merge/commit/push workflow via `git2dart` (libgit2 FFI bindings)
- Conflict resolution screen (Keep Mine / Keep Theirs / Keep Both)
- Sync order commit → pull → push: edits on two devices become a conflict, never a silent overwrite
- Optional auto sync: on app open/resume or periodically while the app is open
- Switch the local branch to the configured one (merges the old branch, keeps it as a backup)
- Git runs in a background isolate with network timeouts, so the UI never freezes
- Sync history bottom sheet with operation log
- Visual sync status indicator in app bar
- Credentials stored securely via `flutter_secure_storage`

### Collections
- Group notes by tags
- Create collections with custom name and filter tags
- Filter note list by selected collection
- Edit, delete (keeps the notes) and drag to reorder collections

### Settings
- Theme picker (Dark / Light / System)
- Git repository setup with connection status
- Font & size, toolbar layout (show/hide/reorder), sync frequency
- Language: System / Tiếng Việt / English
- Export notes as ZIP archive via the share sheet
- Import notes from ZIP — never overwrites: identical files are skipped, different ones are saved as copies

### Onboarding
- 3-step welcome wizard (Local-First, Git Sync, Built for Developers)
- Optional Git setup during onboarding
- Sample "Welcome to DevNotes" note with Markdown guide
- Interactive feature tooltips for first-time users

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter (Android, iOS*) |
| State Management | Riverpod |
| Routing | go_router |
| Local Storage | File system (.md files with YAML frontmatter) |
| Search | SQLite FTS5 via sqlite3 |
| Git Sync | git2dart (libgit2 FFI bindings) |
| Secure Storage | flutter_secure_storage |
| Markdown Preview | flutter_markdown |
| Theme | Custom dark/light theme with AppColorScheme tokens |

*iOS: app runs but Git sync requires git2dart iOS support (not yet available).

## Data Structure

Each note is a `.md` file with YAML frontmatter:

```yaml
---
title: "My Note Title"
tags: ["flutter", "dart"]
createdAt: "2026-03-27T10:00:00Z"
updatedAt: "2026-03-27T10:30:00Z"
---

# Note content starts here

Your Markdown content...
```

## Project Structure

```
lib/
  app/                    # App widget, router
  core/
    file_system/          # NoteFileRepository, FrontmatterParser, MetadataDatabase
    git_client/           # GitClient interface, Git2dartClient implementation
    search_engine/        # SQLite FTS5 SearchEngine
    theme/                # AppTheme, AppColors, ThemeNotifier
    utils/                # Enums (SyncStatus, ThemePreference, etc.)
  features/
    editor/               # Markdown editor screen, toolbar, providers
    git_sync/             # Git setup, sync service, conflict resolution
    onboarding/           # Welcome wizard, tooltips
    settings/             # Settings screen, preferences, export/import
    workspace/            # Workspace explorer, note list, collections, search UI
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.27.0
- Android SDK with NDK 27.0 (auto-installed on first build)
- An Android device or emulator

### Build & Run

```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build debug APK
flutter build apk --debug

# Run tests
flutter test
```

### Git Sync Setup

1. Create a private repository on GitHub (can be empty)
2. Generate a Personal Access Token (Settings > Developer Settings > Tokens)
3. In DevNotes: Settings > Git Repository > enter URL, username, and PAT
4. Tap "Sync Now" in the workspace

## Stats

- 55 Dart source files
- 64 tests passing
- 0 analyzer issues
- 53 commits

## Known Limitations

- Git sync is Android-only (iOS waiting for git2dart support)
- SSH authentication not supported (HTTPS with PAT only)
- Single branch sync (main only)
- Manual sync only (no auto-sync yet)
- Font files are placeholders (need real .ttf files for JetBrainsMono/FiraCode)

## License

Private project.
