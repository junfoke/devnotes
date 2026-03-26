# DevNotes — Progress Report

> Last updated: 2026-03-26

## Project Status: Phase 2 of 10 complete

**46 tests pass. 0 analyzer errors. 9 commits.**

---

## Completed

### Phase 1: Project Setup & Core Infrastructure (Tasks 1-4)

| Task | What | Commit |
|------|------|--------|
| 1 | Flutter project init, pubspec, folder structure | `affa9cd` |
| 2 | Core models: NoteFile, Collection, SyncState, GitConfig, EditorPreferences, enums | `4872ce3` |
| 3 | Theme system: dark/light/system, AppColors tokens, ThemeNotifier provider | `0985171` |
| 4 | go_router with 8 routes, 8 placeholder screens, App widget | `ba3324d` |
| - | Fix deprecated Color.value | `0610c08` |

### Phase 2: File System & Data Layer (Tasks 5-8)

| Task | What | Commit |
|------|------|--------|
| 5 | YAML Frontmatter parser (parse/serialize/roundtrip) — 5 tests | `46c7fcd` |
| 6 | NoteFileRepository (create/list/read/save/delete/rename) — 7 tests | `ff86c11` |
| 7 | SQLite MetadataDatabase (sync status, conflict ref, sync log) — 6 tests | `a56c980` |
| 8 | Riverpod providers: noteList, create, delete, rename, selectedCollection | `cd3d8e2` |

---

## Not Yet Started

### Phase 3: Workspace Explorer UI (Tasks 9-10)
- Task 9: Workspace screen shell (AppBar, SearchBar, CollectionsRow, NoteListItem, EmptyState widgets)
- Task 10: Create/Delete/Rename note flows with dialogs and providers wiring

### Phase 4: Markdown Editor (Tasks 11-12)
- Task 11: Editor screen with Edit/Preview swipe, auto-save, save status indicator
- Task 12: Scrollable Markdown toolbar with all syntax actions

### Phase 5: Full-text Search (Tasks 13-14)
- Task 13: SQLite FTS5 search engine (index/search/remove)
- Task 14: Search UI integration into Workspace

### Phase 6: Collections (Task 15)
- Task 15: Collections JSON repository, providers, UI integration

### Phase 7: Git Sync (Tasks 16-19)
- Task 16: Abstract GitClient interface + libgit2dart stub
- Task 17: Git Setup screen with secure storage
- Task 18: Sync engine + Sync History bottom sheet
- Task 19: Conflict resolution (parser + screen)

### Phase 8: Settings (Task 20)
- Task 20: Settings screen (git, sync, editor, appearance, data, collections, about)

### Phase 9: Onboarding (Tasks 21-22)
- Task 21: Welcome wizard (swipeable cards, git setup, sample first note)
- Task 22: Feature tooltips (tutorial_coach_mark)

### Phase 10: Final Integration (Tasks 23-25)
- Task 23: Export/Import with zip archive
- Task 24: Wire all providers, init search index, apply editor preferences
- Task 25: Final test run, cleanup, analyzer check

---

## Known Issues / Notes

1. **`libgit2dart` commented out** in pubspec.yaml — needs native platform setup before use (Phase 7)
2. **`flutter_markdown` deprecated** — consider migrating to `flutter_markdown_plus` before production
3. **Font files are empty placeholders** — need real JetBrainsMono and FiraCode `.ttf` files in `assets/fonts/`
4. **SyncStatus enum has redundant values** — both `idle/syncing/success/error` (from Task 2) and `pending/synced/conflict` (from Task 7). Needs consolidation in Phase 7.

---

## Key Files Reference

| What | Path |
|------|------|
| Design spec | `docs/superpowers/specs/2026-03-26-devnotes-full-design.md` |
| Implementation plan | `docs/superpowers/plans/2026-03-26-devnotes-implementation.md` |
| UI mockups | `docs/untitled.pen` (3 frames: Workspace, Editor, Git Setup) |
| Original specs | `docs/01_project_overview.md` through `docs/05_implementation_phases.md` |

## How to Resume

1. Read this file for context
2. Read the implementation plan at `docs/superpowers/plans/2026-03-26-devnotes-implementation.md`
3. Continue with **Phase 3: Workspace Explorer UI** (Tasks 9-10)
4. Use subagent-driven-development, executing phase by phase with user review between phases
