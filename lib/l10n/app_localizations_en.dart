// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSkip => 'Skip';

  @override
  String get untitled => 'Untitled';

  @override
  String get unknownError => 'Unknown error';

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get gitBusy => 'A sync is in progress — try again when it\'s done.';

  @override
  String get unresolvedConflictsBeforeSwitch =>
      'There are unresolved conflicts — resolve them before switching branch.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGit => 'Git';

  @override
  String get settingsGitRepository => 'Git repository';

  @override
  String get settingsSectionSync => 'Sync';

  @override
  String get settingsSyncFrequency => 'Sync frequency';

  @override
  String get settingsSectionEditor => 'Editor';

  @override
  String get settingsFontAndSize => 'Font & size';

  @override
  String get settingsToolbarLayout => 'Toolbar layout';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeTooltip => 'Choose theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageTooltip => 'Choose language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsExportNotes => 'Export notes';

  @override
  String get settingsExportSubject => 'DevNotes export';

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get settingsImportNotes => 'Import notes';

  @override
  String get settingsRebuildIndex => 'Rebuild search index';

  @override
  String get settingsSectionCollections => 'Collections';

  @override
  String get settingsManageCollections => 'Manage collections';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutTagline => 'Local-first Markdown notes for devs';

  @override
  String settingsSaveFailed(String error) {
    return 'Couldn\'t save settings: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String importInvalidZip(String error) {
    return 'Not a valid ZIP file: $error';
  }

  @override
  String get importDoneTitle => 'Notes imported';

  @override
  String importAdded(int count) {
    return 'Added: $count';
  }

  @override
  String importSkippedIdentical(int count) {
    return 'Skipped (identical copy exists): $count';
  }

  @override
  String importCopied(int count) {
    return 'Name already taken, saved as a copy: $count';
  }

  @override
  String importRejected(int count) {
    return 'Rejected (unsafe path): $count';
  }

  @override
  String get rebuildIndexInProgress => 'Rebuilding search index...';

  @override
  String rebuildIndexDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rebuilt the index for $count notes',
      one: 'Rebuilt the index for 1 note',
    );
    return '$_temp0';
  }

  @override
  String rebuildIndexFailed(String error) {
    return 'Rebuilding the index failed: $error';
  }

  @override
  String get fontSize => 'Size';

  @override
  String get fontPreviewSample => '## Preview\nconst answer = 42; // **bold**';

  @override
  String get toolbarLayoutHint => 'Toggle buttons and drag to reorder.';

  @override
  String get toolbarItemH1 => 'Heading 1';

  @override
  String get toolbarItemH2 => 'Heading 2';

  @override
  String get toolbarItemH3 => 'Heading 3';

  @override
  String get toolbarItemBold => 'Bold';

  @override
  String get toolbarItemItalic => 'Italic';

  @override
  String get toolbarItemStrikethrough => 'Strikethrough';

  @override
  String get toolbarItemLink => 'Link';

  @override
  String get toolbarItemImage => 'Image';

  @override
  String get toolbarItemCodeInline => 'Inline code';

  @override
  String get toolbarItemCodeBlock => 'Code block';

  @override
  String get toolbarItemChecklist => 'Checklist';

  @override
  String get toolbarItemListUnordered => 'Bulleted list';

  @override
  String get toolbarItemListOrdered => 'Numbered list';

  @override
  String get toolbarItemQuote => 'Quote';

  @override
  String get toolbarItemTable => 'Table';

  @override
  String get toolbarItemHr => 'Horizontal rule';

  @override
  String get syncFrequencyManual => 'Manual';

  @override
  String get syncFrequencyManualDesc => 'Only sync when you tap Sync.';

  @override
  String get syncFrequencyOnOpen => 'When the app opens';

  @override
  String get syncFrequencyOnOpenDesc =>
      'Sync when the app opens and when you return to it (at least 5 minutes apart).';

  @override
  String get syncFrequencyPeriodic => 'Periodic';

  @override
  String get syncFrequencyPeriodicDesc =>
      'Like \"When the app opens\", plus periodic sync while the app is open.';

  @override
  String syncFrequencyMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get syncFrequencyFootnote =>
      'The app doesn\'t sync in the background once closed. Auto-sync errors and conflicts show on the status dot next to the Sync button.';

  @override
  String get tooltipSearchTitle => 'Search';

  @override
  String get tooltipSearchDesc =>
      'Search through all your notes with full-text search.';

  @override
  String get tooltipSyncTitle => 'Sync';

  @override
  String get tooltipSyncDesc =>
      'Tap to sync your notes with your Git repository.';

  @override
  String get tooltipNewNoteDesc => 'Create a new Markdown note.';

  @override
  String get tooltipToolbarTitle => 'Markdown toolbar';

  @override
  String get tooltipToolbarDesc =>
      'Quick-insert Markdown syntax — headings, bold, code blocks, and more.';

  @override
  String get tooltipPreviewTitle => 'Swipe to preview';

  @override
  String get tooltipPreviewDesc =>
      'Swipe left to see a rendered preview of your Markdown.';

  @override
  String get newNote => 'New note';

  @override
  String noteDeleteFailed(String error) {
    return 'Couldn\'t delete note: $error';
  }

  @override
  String noteCreateFailed(String error) {
    return 'Couldn\'t create note: $error';
  }

  @override
  String noteRenameFailed(String error) {
    return 'Couldn\'t rename note: $error';
  }

  @override
  String collectionCreateFailed(String error) {
    return 'Couldn\'t create collection: $error';
  }

  @override
  String collectionEditFailed(String error) {
    return 'Couldn\'t update collection: $error';
  }

  @override
  String collectionDeleteFailed(String error) {
    return 'Couldn\'t delete collection: $error';
  }

  @override
  String syncHistoryLoadFailed(String error) {
    return 'Couldn\'t load sync history: $error';
  }

  @override
  String get deleteNoteTitle => 'Delete note';

  @override
  String deleteNoteConfirm(String title) {
    return 'Delete \"$title\"? This can\'t be undone.';
  }

  @override
  String get syncAlreadyRunning =>
      'A sync is already running — wait for it to finish.';

  @override
  String syncError(String error) {
    return 'Sync error: $error';
  }

  @override
  String syncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced — $count files changed',
      one: 'Synced — 1 file changed',
    );
    return '$_temp0';
  }

  @override
  String syncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get searchNoResults => 'No results found';

  @override
  String searchError(String error) {
    return 'Search error: $error';
  }

  @override
  String get collectionNoNotes => 'No notes in this collection';

  @override
  String get collectionShowAll => 'Show all notes';

  @override
  String noteListLoadFailed(String error) {
    return 'Couldn\'t load notes: $error';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get searchHint => 'Search notes...';

  @override
  String get searchClearTooltip => 'Clear search';

  @override
  String get emptyNotesTitle => 'No notes yet';

  @override
  String get emptyNotesSubtitle => 'Create your first note to get started';

  @override
  String get emptyNotesButton => 'Create your first note';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get allNotes => 'All notes';

  @override
  String get noteTitleHint => 'Note title';

  @override
  String get tagsHint => 'Tags (comma separated)';

  @override
  String get titleRequired => 'Please enter a title';

  @override
  String get titleMustDiffer =>
      'The new title must be different from the current one';

  @override
  String get renameNoteTitle => 'Rename note';

  @override
  String get newTitleHint => 'New title';

  @override
  String get newCollectionTitle => 'New collection';

  @override
  String get editCollectionTitle => 'Edit collection';

  @override
  String get collectionNameHint => 'Collection name';

  @override
  String get filterTagsHint => 'Filter tags (comma separated)';

  @override
  String deleteCollectionTitle(String name) {
    return 'Delete collection \"$name\"?';
  }

  @override
  String get deleteCollectionBody =>
      'Only the group is removed. Its notes stay in All notes.';

  @override
  String get collectionsEmpty =>
      'No collections yet.\nCreate one with the + button on the home screen.';

  @override
  String noteSaveFailed(String error) {
    return 'Couldn\'t save note: $error';
  }

  @override
  String noteOpenFailed(String error) {
    return 'Couldn\'t open note: $error';
  }

  @override
  String get externalChangeTitle => 'Note changed elsewhere';

  @override
  String get externalChangeBody =>
      'While you were editing, this note was changed somewhere else (for example by a sync). To avoid overwriting that version, choose:';

  @override
  String get externalChangeReload => 'Load the new version';

  @override
  String get externalChangeKeepMine => 'Save my version as a new note';

  @override
  String editedCopyTitle(String title) {
    return '$title (edited)';
  }

  @override
  String savedAsCopy(String title) {
    return 'Saved your version as \"$title\".';
  }

  @override
  String copySaveFailed(String error) {
    return 'Couldn\'t save the copy: $error';
  }

  @override
  String get editorMenuShare => 'Share';

  @override
  String get editorMenuEditTags => 'Edit tags';

  @override
  String get editorMenuInfo => 'Info';

  @override
  String shareFailed(String error) {
    return 'Couldn\'t share: $error';
  }

  @override
  String noteInfoFile(String name) {
    return 'File: $name';
  }

  @override
  String noteInfoTags(String tags) {
    return 'Tags: $tags';
  }

  @override
  String noteInfoCreated(String date) {
    return 'Created: $date';
  }

  @override
  String noteInfoUpdated(String date) {
    return 'Modified: $date';
  }

  @override
  String noteInfoWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String noteInfoChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String get editorHint => 'Start writing...';

  @override
  String get editTagsHint => 'Tags, separated by commas';

  @override
  String linkOpenFailed(String url) {
    return 'Couldn\'t open link: $url';
  }

  @override
  String get gitSetupTitle => 'Git setup';

  @override
  String gitConfigLoadFailed(String error) {
    return 'Couldn\'t read Git settings: $error';
  }

  @override
  String gitConfigSaveFailed(String error) {
    return 'Couldn\'t save Git settings: $error';
  }

  @override
  String gitConfigDeleteFailed(String error) {
    return 'Couldn\'t remove Git settings: $error';
  }

  @override
  String get gitMissingFieldsCheck =>
      'Enter the URL, username and PAT before checking.';

  @override
  String get gitMissingFieldsSave => 'Enter the URL, username and PAT to save.';

  @override
  String get gitMissingFieldsConnect =>
      'Enter the URL, username and PAT to connect.';

  @override
  String get gitCredentialsSaved => 'Git credentials saved';

  @override
  String get gitCredentialsRemoved => 'Git credentials removed';

  @override
  String get disconnectRepository => 'Disconnect repository';

  @override
  String get disconnectBody =>
      'This removes your saved Git credentials. Your local notes won\'t be affected.';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get branchMismatchTitle => 'Branch doesn\'t match settings';

  @override
  String branchMismatchBody(String local, String configured) {
    return 'Notes on this device are on branch \"$local\", but the configured branch is \"$configured\". Sync is currently pushing to \"$local\".';
  }

  @override
  String switchToBranch(String branch) {
    return 'Switch to \"$branch\"';
  }

  @override
  String switchBranchConfirmTitle(String branch) {
    return 'Switch to \"$branch\"?';
  }

  @override
  String switchBranchConfirmBody(String from, String to) {
    return 'Notes from \"$from\" will be merged into \"$to\" and pushed to the remote. No note is deleted; branch \"$from\" is kept as a backup.\n\nIf the same note was edited differently on the two branches, you\'ll be taken to the conflict resolution screen.';
  }

  @override
  String get switchBranchButton => 'Switch';

  @override
  String switchedWithConflicts(String branch, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Switched to \"$branch\"; $count notes have conflicts. Resolve them, then tap Sync.',
      one:
          'Switched to \"$branch\"; 1 note has a conflict. Resolve it, then tap Sync.',
    );
    return '$_temp0';
  }

  @override
  String switchedAndPushed(String branch) {
    return 'Switched to \"$branch\" and pushed to the remote.';
  }

  @override
  String switchedNotPushed(String branch, String error) {
    return 'Switched to \"$branch\" but couldn\'t push yet ($error). The next sync will push it.';
  }

  @override
  String switchBranchFailed(String error) {
    return 'Switching branch failed: $error';
  }

  @override
  String get repoConfigured => 'Repository configured';

  @override
  String get gitSetupIntro =>
      'Connect your private Git repository to sync notes across devices. Your data stays in your control.';

  @override
  String get gitFieldRemoteUrl => 'Git remote URL';

  @override
  String get gitFieldUsername => 'Username';

  @override
  String get gitFieldPat => 'Personal access token (PAT)';

  @override
  String get gitFieldBranch => 'Branch';

  @override
  String get securityTitle => 'Your data is secure';

  @override
  String get securityBody =>
      'Credentials are stored locally on your device using encrypted storage.';

  @override
  String get checkingConnection => 'Checking…';

  @override
  String get checkConnection => 'Check connection';

  @override
  String get updateCredentials => 'Update credentials';

  @override
  String get saveCredentials => 'Save credentials';

  @override
  String remoteCheckOkEmpty(String branch) {
    return 'Connected. The remote is empty — the first sync will push your notes to branch \"$branch\".';
  }

  @override
  String remoteCheckOkFound(String branch) {
    return 'Connected. Found branch \"$branch\" on the remote.';
  }

  @override
  String get remoteCheckInvalidCredentials =>
      'Wrong credentials. Check your username and PAT — the PAT may have expired or be missing the \"repo\" scope.';

  @override
  String get remoteCheckRepoNotFound =>
      'Repository not found. Check the URL. If the repo is private, the PAT must also have access to that repo.';

  @override
  String get remoteCheckNetworkUnreachable =>
      'Couldn\'t reach the remote. Check your network connection and try again.';

  @override
  String remoteCheckBranchNotFound(String branch, String found) {
    return 'Connected, but the remote has no branch \"$branch\". Existing branches: $found.';
  }

  @override
  String remoteCheckUnknown(String detail) {
    return 'Check failed: $detail';
  }

  @override
  String get onboardingGitIntro =>
      'Connect your private Git repository to sync notes across devices. You can always set this up later in Settings.';

  @override
  String get connectRepository => 'Connect repository';

  @override
  String get skipGitSetup => 'Skip for now — set up later in Settings';

  @override
  String get onboardingLocalFirstTitle => 'Local-first';

  @override
  String get onboardingLocalFirstDesc =>
      'Your notes live on your device as plain .md files. No cloud lock-in, no subscriptions.';

  @override
  String get onboardingGitSyncTitle => 'Git sync';

  @override
  String get onboardingGitSyncDesc =>
      'Sync via your own GitHub or GitLab repo. You own the data, always.';

  @override
  String get onboardingDevTitle => 'Built for developers';

  @override
  String get onboardingDevDesc =>
      'Markdown editing with syntax highlighting, code blocks, and a customizable toolbar.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get firstNoteTitle => 'Your first note';

  @override
  String get firstNoteBody =>
      'We\'ll create a sample note with a Markdown guide to get you started.';

  @override
  String get firstNoteButton => 'Create & start';

  @override
  String get conflictTitle => 'Resolve conflicts';

  @override
  String get conflictThisDevice => 'this device';

  @override
  String get conflictRemote => 'remote';

  @override
  String conflictVersionOn(String side) {
    return '$side VERSION';
  }

  @override
  String conflictKeep(String side) {
    return 'Keep $side version';
  }

  @override
  String get conflictKeepBoth => 'Keep both';

  @override
  String conflictResolveFailed(String error) {
    return 'Couldn\'t resolve the conflict: $error';
  }

  @override
  String conflictRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflicting notes left.',
      one: '1 conflicting note left.',
    );
    return '$_temp0';
  }

  @override
  String get conflictAllResolved =>
      'All conflicts resolved — tap Sync to finish.';

  @override
  String conflictReadFailed(String error) {
    return 'Couldn\'t read the file: $error';
  }

  @override
  String get conflictNoMarkers =>
      'This file no longer has conflict markers — it looks like it was fixed by hand.';

  @override
  String get conflictMarkResolved => 'Mark as resolved';

  @override
  String get syncHistoryTitle => 'Sync history';

  @override
  String syncHistoryLastSync(String date) {
    return 'Last sync: $date';
  }

  @override
  String get syncHistoryEmpty => 'No sync history yet';

  @override
  String syncHistoryEntry(String action, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$action — $count files',
      one: '$action — 1 file',
    );
    return '$_temp0';
  }

  @override
  String get editorToolFont => 'Font';

  @override
  String get editorToolSizeDown => 'Smaller text';

  @override
  String get editorToolSizeUp => 'Larger text';

  @override
  String get editorToolLineHeight => 'Line spacing';

  @override
  String get editorToolWordWrap => 'Word wrap';

  @override
  String get editorToolFocusMode => 'Focus mode';

  @override
  String get editorToolTheme => 'Theme';

  @override
  String get editorToolUndo => 'Undo';

  @override
  String get editorToolRedo => 'Redo';

  @override
  String get editorToolIndent => 'Indent';

  @override
  String get editorToolOutdent => 'Outdent';

  @override
  String get editorToolMoveUp => 'Move line up';

  @override
  String get editorToolMoveDown => 'Move line down';

  @override
  String get editorToolDuplicateLine => 'Duplicate line';

  @override
  String get editorToolDeleteLine => 'Delete line';

  @override
  String get editorToolFindReplace => 'Find & replace';

  @override
  String get editorToolDateTime => 'Insert date & time';

  @override
  String get editorToolSymbols => 'Symbols';

  @override
  String get editorToolNoteLink => 'Note link';

  @override
  String get editorToolTemplate => 'Template';

  @override
  String get editorToolOutline => 'Outline';

  @override
  String get editorToolStats => 'Statistics';

  @override
  String get editorToolsButton => 'Editor tools';

  @override
  String get editorToolGroupDisplay => 'Display';

  @override
  String get editorToolGroupEdit => 'Edit';

  @override
  String get editorToolGroupInsert => 'Insert';

  @override
  String get editorToolGroupView => 'View';

  @override
  String get editorToolGroupFormat => 'Format';

  @override
  String get editorFontSystem => 'System font';

  @override
  String get lineHeightCompact => 'Compact';

  @override
  String get lineHeightNormal => 'Normal';

  @override
  String get lineHeightRelaxed => 'Relaxed';

  @override
  String get editorToolsCustomize => 'Customize';

  @override
  String get editorToolsDone => 'Done';

  @override
  String get editorToolsPin => 'Pin';

  @override
  String get editorToolsShowInSheet => 'Show in sheet';

  @override
  String get editorToolsCustomizeHint =>
      'Pin a tool to the toolbar, or hide it from this sheet. Hidden tools stay listed here so you can bring them back.';
}
