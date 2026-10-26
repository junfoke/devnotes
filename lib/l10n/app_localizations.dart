import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @errorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetail(String error);

  /// No description provided for @gitBusy.
  ///
  /// In en, this message translates to:
  /// **'A sync is in progress — try again when it\'s done.'**
  String get gitBusy;

  /// No description provided for @unresolvedConflictsBeforeSwitch.
  ///
  /// In en, this message translates to:
  /// **'There are unresolved conflicts — resolve them before switching branch.'**
  String get unresolvedConflictsBeforeSwitch;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGit.
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get settingsSectionGit;

  /// No description provided for @settingsGitRepository.
  ///
  /// In en, this message translates to:
  /// **'Git repository'**
  String get settingsGitRepository;

  /// No description provided for @settingsSectionSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSectionSync;

  /// No description provided for @settingsSyncFrequency.
  ///
  /// In en, this message translates to:
  /// **'Sync frequency'**
  String get settingsSyncFrequency;

  /// No description provided for @settingsSectionEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsSectionEditor;

  /// No description provided for @settingsFontAndSize.
  ///
  /// In en, this message translates to:
  /// **'Font & size'**
  String get settingsFontAndSize;

  /// No description provided for @settingsToolbarLayout.
  ///
  /// In en, this message translates to:
  /// **'Toolbar layout'**
  String get settingsToolbarLayout;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose theme'**
  String get settingsThemeTooltip;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsLanguageTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsExportNotes.
  ///
  /// In en, this message translates to:
  /// **'Export notes'**
  String get settingsExportNotes;

  /// No description provided for @settingsExportSubject.
  ///
  /// In en, this message translates to:
  /// **'DevNotes export'**
  String get settingsExportSubject;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsImportNotes.
  ///
  /// In en, this message translates to:
  /// **'Import notes'**
  String get settingsImportNotes;

  /// No description provided for @settingsRebuildIndex.
  ///
  /// In en, this message translates to:
  /// **'Rebuild search index'**
  String get settingsRebuildIndex;

  /// No description provided for @settingsSectionCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get settingsSectionCollections;

  /// No description provided for @settingsManageCollections.
  ///
  /// In en, this message translates to:
  /// **'Manage collections'**
  String get settingsManageCollections;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Local-first Markdown notes for devs'**
  String get settingsAboutTagline;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save settings: {error}'**
  String settingsSaveFailed(String error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @importInvalidZip.
  ///
  /// In en, this message translates to:
  /// **'Not a valid ZIP file: {error}'**
  String importInvalidZip(String error);

  /// No description provided for @importDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes imported'**
  String get importDoneTitle;

  /// No description provided for @importAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {count}'**
  String importAdded(int count);

  /// No description provided for @importSkippedIdentical.
  ///
  /// In en, this message translates to:
  /// **'Skipped (identical copy exists): {count}'**
  String importSkippedIdentical(int count);

  /// No description provided for @importCopied.
  ///
  /// In en, this message translates to:
  /// **'Name already taken, saved as a copy: {count}'**
  String importCopied(int count);

  /// No description provided for @importRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected (unsafe path): {count}'**
  String importRejected(int count);

  /// No description provided for @rebuildIndexInProgress.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding search index...'**
  String get rebuildIndexInProgress;

  /// No description provided for @rebuildIndexDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Rebuilt the index for 1 note} other{Rebuilt the index for {count} notes}}'**
  String rebuildIndexDone(int count);

  /// No description provided for @rebuildIndexFailed.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding the index failed: {error}'**
  String rebuildIndexFailed(String error);

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fontSize;

  /// No description provided for @fontPreviewSample.
  ///
  /// In en, this message translates to:
  /// **'## Preview\nconst answer = 42; // **bold**'**
  String get fontPreviewSample;

  /// No description provided for @toolbarLayoutHint.
  ///
  /// In en, this message translates to:
  /// **'Pin tools to the toolbar, hide them from the ⋯ sheet, and drag pinned items to reorder. Changes apply to the editor right away.'**
  String get toolbarLayoutHint;

  /// No description provided for @toolbarLayoutPinnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned to the toolbar'**
  String get toolbarLayoutPinnedTitle;

  /// No description provided for @toolbarLayoutOthersTitle.
  ///
  /// In en, this message translates to:
  /// **'Not pinned'**
  String get toolbarLayoutOthersTitle;

  /// No description provided for @toolbarItemH1.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get toolbarItemH1;

  /// No description provided for @toolbarItemH2.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get toolbarItemH2;

  /// No description provided for @toolbarItemH3.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get toolbarItemH3;

  /// No description provided for @toolbarItemBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get toolbarItemBold;

  /// No description provided for @toolbarItemItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get toolbarItemItalic;

  /// No description provided for @toolbarItemStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get toolbarItemStrikethrough;

  /// No description provided for @toolbarItemLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get toolbarItemLink;

  /// No description provided for @toolbarItemImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get toolbarItemImage;

  /// No description provided for @toolbarItemCodeInline.
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get toolbarItemCodeInline;

  /// No description provided for @toolbarItemCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get toolbarItemCodeBlock;

  /// No description provided for @toolbarItemChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get toolbarItemChecklist;

  /// No description provided for @toolbarItemListUnordered.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get toolbarItemListUnordered;

  /// No description provided for @toolbarItemListOrdered.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get toolbarItemListOrdered;

  /// No description provided for @toolbarItemQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get toolbarItemQuote;

  /// No description provided for @toolbarItemTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get toolbarItemTable;

  /// No description provided for @toolbarItemHr.
  ///
  /// In en, this message translates to:
  /// **'Horizontal rule'**
  String get toolbarItemHr;

  /// No description provided for @syncFrequencyManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get syncFrequencyManual;

  /// No description provided for @syncFrequencyManualDesc.
  ///
  /// In en, this message translates to:
  /// **'Only sync when you tap Sync.'**
  String get syncFrequencyManualDesc;

  /// No description provided for @syncFrequencyOnOpen.
  ///
  /// In en, this message translates to:
  /// **'When the app opens'**
  String get syncFrequencyOnOpen;

  /// No description provided for @syncFrequencyOnOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync when the app opens and when you return to it (at least 5 minutes apart).'**
  String get syncFrequencyOnOpenDesc;

  /// No description provided for @syncFrequencyPeriodic.
  ///
  /// In en, this message translates to:
  /// **'Periodic'**
  String get syncFrequencyPeriodic;

  /// No description provided for @syncFrequencyPeriodicDesc.
  ///
  /// In en, this message translates to:
  /// **'Like \"When the app opens\", plus periodic sync while the app is open.'**
  String get syncFrequencyPeriodicDesc;

  /// No description provided for @syncFrequencyMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String syncFrequencyMinutes(int minutes);

  /// No description provided for @syncFrequencyFootnote.
  ///
  /// In en, this message translates to:
  /// **'The app doesn\'t sync in the background once closed. Auto-sync errors and conflicts show on the status dot next to the Sync button.'**
  String get syncFrequencyFootnote;

  /// No description provided for @tooltipSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tooltipSearchTitle;

  /// No description provided for @tooltipSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Search through all your notes with full-text search.'**
  String get tooltipSearchDesc;

  /// No description provided for @tooltipSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get tooltipSyncTitle;

  /// No description provided for @tooltipSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap to sync your notes with your Git repository.'**
  String get tooltipSyncDesc;

  /// No description provided for @tooltipNewNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new Markdown note.'**
  String get tooltipNewNoteDesc;

  /// No description provided for @tooltipToolbarTitle.
  ///
  /// In en, this message translates to:
  /// **'Markdown toolbar'**
  String get tooltipToolbarTitle;

  /// No description provided for @tooltipToolbarDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick-insert Markdown syntax — headings, bold, code blocks, and more.'**
  String get tooltipToolbarDesc;

  /// No description provided for @tooltipPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to preview'**
  String get tooltipPreviewTitle;

  /// No description provided for @tooltipPreviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to see a rendered preview of your Markdown.'**
  String get tooltipPreviewDesc;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @noteDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete note: {error}'**
  String noteDeleteFailed(String error);

  /// No description provided for @noteCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create note: {error}'**
  String noteCreateFailed(String error);

  /// No description provided for @noteRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename note: {error}'**
  String noteRenameFailed(String error);

  /// No description provided for @collectionCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create collection: {error}'**
  String collectionCreateFailed(String error);

  /// No description provided for @collectionEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update collection: {error}'**
  String collectionEditFailed(String error);

  /// No description provided for @collectionDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete collection: {error}'**
  String collectionDeleteFailed(String error);

  /// No description provided for @syncHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load sync history: {error}'**
  String syncHistoryLoadFailed(String error);

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This can\'t be undone.'**
  String deleteNoteConfirm(String title);

  /// No description provided for @syncAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'A sync is already running — wait for it to finish.'**
  String get syncAlreadyRunning;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error: {error}'**
  String syncError(String error);

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Synced — 1 file changed} other{Synced — {count} files changed}}'**
  String syncDone(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailed(String error);

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search error: {error}'**
  String searchError(String error);

  /// No description provided for @collectionNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes in this collection'**
  String get collectionNoNotes;

  /// No description provided for @collectionShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all notes'**
  String get collectionShowAll;

  /// No description provided for @noteListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notes: {error}'**
  String noteListLoadFailed(String error);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get searchHint;

  /// No description provided for @searchClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearTooltip;

  /// No description provided for @emptyNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get emptyNotesTitle;

  /// No description provided for @emptyNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first note to get started'**
  String get emptyNotesSubtitle;

  /// No description provided for @emptyNotesButton.
  ///
  /// In en, this message translates to:
  /// **'Create your first note'**
  String get emptyNotesButton;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All notes'**
  String get allNotes;

  /// No description provided for @noteTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get noteTitleHint;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get tagsHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get titleRequired;

  /// No description provided for @titleMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'The new title must be different from the current one'**
  String get titleMustDiffer;

  /// No description provided for @renameNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename note'**
  String get renameNoteTitle;

  /// No description provided for @newTitleHint.
  ///
  /// In en, this message translates to:
  /// **'New title'**
  String get newTitleHint;

  /// No description provided for @newCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get newCollectionTitle;

  /// No description provided for @editCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit collection'**
  String get editCollectionTitle;

  /// No description provided for @collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionNameHint;

  /// No description provided for @filterTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Filter tags (comma separated)'**
  String get filterTagsHint;

  /// No description provided for @deleteCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete collection \"{name}\"?'**
  String deleteCollectionTitle(String name);

  /// No description provided for @deleteCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'Only the group is removed. Its notes stay in All notes.'**
  String get deleteCollectionBody;

  /// No description provided for @collectionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No collections yet.\nCreate one with the + button on the home screen.'**
  String get collectionsEmpty;

  /// No description provided for @noteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save note: {error}'**
  String noteSaveFailed(String error);

  /// No description provided for @noteOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open note: {error}'**
  String noteOpenFailed(String error);

  /// No description provided for @externalChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Note changed elsewhere'**
  String get externalChangeTitle;

  /// No description provided for @externalChangeBody.
  ///
  /// In en, this message translates to:
  /// **'While you were editing, this note was changed somewhere else (for example by a sync). To avoid overwriting that version, choose:'**
  String get externalChangeBody;

  /// No description provided for @externalChangeReload.
  ///
  /// In en, this message translates to:
  /// **'Load the new version'**
  String get externalChangeReload;

  /// No description provided for @externalChangeKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Save my version as a new note'**
  String get externalChangeKeepMine;

  /// No description provided for @editedCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} (edited)'**
  String editedCopyTitle(String title);

  /// No description provided for @savedAsCopy.
  ///
  /// In en, this message translates to:
  /// **'Saved your version as \"{title}\".'**
  String savedAsCopy(String title);

  /// No description provided for @copySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the copy: {error}'**
  String copySaveFailed(String error);

  /// No description provided for @editorMenuShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get editorMenuShare;

  /// No description provided for @editorMenuEditTags.
  ///
  /// In en, this message translates to:
  /// **'Edit tags'**
  String get editorMenuEditTags;

  /// No description provided for @editorMenuInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get editorMenuInfo;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share: {error}'**
  String shareFailed(String error);

  /// No description provided for @noteInfoFile.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String noteInfoFile(String name);

  /// No description provided for @noteInfoTags.
  ///
  /// In en, this message translates to:
  /// **'Tags: {tags}'**
  String noteInfoTags(String tags);

  /// No description provided for @noteInfoCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String noteInfoCreated(String date);

  /// No description provided for @noteInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Modified: {date}'**
  String noteInfoUpdated(String date);

  /// No description provided for @noteInfoWords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String noteInfoWords(int count);

  /// No description provided for @noteInfoChars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}}'**
  String noteInfoChars(int count);

  /// No description provided for @editorHint.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get editorHint;

  /// No description provided for @editTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Tags, separated by commas'**
  String get editTagsHint;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open link: {url}'**
  String linkOpenFailed(String url);

  /// No description provided for @gitSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Git setup'**
  String get gitSetupTitle;

  /// No description provided for @gitConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read Git settings: {error}'**
  String gitConfigLoadFailed(String error);

  /// No description provided for @gitConfigSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save Git settings: {error}'**
  String gitConfigSaveFailed(String error);

  /// No description provided for @gitConfigDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove Git settings: {error}'**
  String gitConfigDeleteFailed(String error);

  /// No description provided for @gitMissingFieldsCheck.
  ///
  /// In en, this message translates to:
  /// **'Enter the URL, username and PAT before checking.'**
  String get gitMissingFieldsCheck;

  /// No description provided for @gitMissingFieldsSave.
  ///
  /// In en, this message translates to:
  /// **'Enter the URL, username and PAT to save.'**
  String get gitMissingFieldsSave;

  /// No description provided for @gitMissingFieldsConnect.
  ///
  /// In en, this message translates to:
  /// **'Enter the URL, username and PAT to connect.'**
  String get gitMissingFieldsConnect;

  /// No description provided for @gitCredentialsSaved.
  ///
  /// In en, this message translates to:
  /// **'Git credentials saved'**
  String get gitCredentialsSaved;

  /// No description provided for @gitCredentialsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Git credentials removed'**
  String get gitCredentialsRemoved;

  /// No description provided for @disconnectRepository.
  ///
  /// In en, this message translates to:
  /// **'Disconnect repository'**
  String get disconnectRepository;

  /// No description provided for @disconnectBody.
  ///
  /// In en, this message translates to:
  /// **'This removes your saved Git credentials. Your local notes won\'t be affected.'**
  String get disconnectBody;

  /// No description provided for @disconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButton;

  /// No description provided for @branchMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch doesn\'t match settings'**
  String get branchMismatchTitle;

  /// No description provided for @branchMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'Notes on this device are on branch \"{local}\", but the configured branch is \"{configured}\". Sync is currently pushing to \"{local}\".'**
  String branchMismatchBody(String local, String configured);

  /// No description provided for @switchToBranch.
  ///
  /// In en, this message translates to:
  /// **'Switch to \"{branch}\"'**
  String switchToBranch(String branch);

  /// No description provided for @switchBranchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to \"{branch}\"?'**
  String switchBranchConfirmTitle(String branch);

  /// No description provided for @switchBranchConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Notes from \"{from}\" will be merged into \"{to}\" and pushed to the remote. No note is deleted; branch \"{from}\" is kept as a backup.\n\nIf the same note was edited differently on the two branches, you\'ll be taken to the conflict resolution screen.'**
  String switchBranchConfirmBody(String from, String to);

  /// No description provided for @switchBranchButton.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchBranchButton;

  /// No description provided for @switchedWithConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Switched to \"{branch}\"; 1 note has a conflict. Resolve it, then tap Sync.} other{Switched to \"{branch}\"; {count} notes have conflicts. Resolve them, then tap Sync.}}'**
  String switchedWithConflicts(String branch, int count);

  /// No description provided for @switchedAndPushed.
  ///
  /// In en, this message translates to:
  /// **'Switched to \"{branch}\" and pushed to the remote.'**
  String switchedAndPushed(String branch);

  /// No description provided for @switchedNotPushed.
  ///
  /// In en, this message translates to:
  /// **'Switched to \"{branch}\" but couldn\'t push yet ({error}). The next sync will push it.'**
  String switchedNotPushed(String branch, String error);

  /// No description provided for @switchBranchFailed.
  ///
  /// In en, this message translates to:
  /// **'Switching branch failed: {error}'**
  String switchBranchFailed(String error);

  /// No description provided for @repoConfigured.
  ///
  /// In en, this message translates to:
  /// **'Repository configured'**
  String get repoConfigured;

  /// No description provided for @gitSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect your private Git repository to sync notes across devices. Your data stays in your control.'**
  String get gitSetupIntro;

  /// No description provided for @gitFieldRemoteUrl.
  ///
  /// In en, this message translates to:
  /// **'Git remote URL'**
  String get gitFieldRemoteUrl;

  /// No description provided for @gitFieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get gitFieldUsername;

  /// No description provided for @gitFieldPat.
  ///
  /// In en, this message translates to:
  /// **'Personal access token (PAT)'**
  String get gitFieldPat;

  /// No description provided for @gitFieldBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get gitFieldBranch;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure'**
  String get securityTitle;

  /// No description provided for @securityBody.
  ///
  /// In en, this message translates to:
  /// **'Credentials are stored locally on your device using encrypted storage.'**
  String get securityBody;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingConnection;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get checkConnection;

  /// No description provided for @updateCredentials.
  ///
  /// In en, this message translates to:
  /// **'Update credentials'**
  String get updateCredentials;

  /// No description provided for @saveCredentials.
  ///
  /// In en, this message translates to:
  /// **'Save credentials'**
  String get saveCredentials;

  /// No description provided for @remoteCheckOkEmpty.
  ///
  /// In en, this message translates to:
  /// **'Connected. The remote is empty — the first sync will push your notes to branch \"{branch}\".'**
  String remoteCheckOkEmpty(String branch);

  /// No description provided for @remoteCheckOkFound.
  ///
  /// In en, this message translates to:
  /// **'Connected. Found branch \"{branch}\" on the remote.'**
  String remoteCheckOkFound(String branch);

  /// No description provided for @remoteCheckInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong credentials. Check your username and PAT — the PAT may have expired or be missing the \"repo\" scope.'**
  String get remoteCheckInvalidCredentials;

  /// No description provided for @remoteCheckRepoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Repository not found. Check the URL. If the repo is private, the PAT must also have access to that repo.'**
  String get remoteCheckRepoNotFound;

  /// No description provided for @remoteCheckNetworkUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the remote. Check your network connection and try again.'**
  String get remoteCheckNetworkUnreachable;

  /// No description provided for @remoteCheckBranchNotFound.
  ///
  /// In en, this message translates to:
  /// **'Connected, but the remote has no branch \"{branch}\". Existing branches: {found}.'**
  String remoteCheckBranchNotFound(String branch, String found);

  /// No description provided for @remoteCheckUnknown.
  ///
  /// In en, this message translates to:
  /// **'Check failed: {detail}'**
  String remoteCheckUnknown(String detail);

  /// No description provided for @onboardingGitIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect your private Git repository to sync notes across devices. You can always set this up later in Settings.'**
  String get onboardingGitIntro;

  /// No description provided for @connectRepository.
  ///
  /// In en, this message translates to:
  /// **'Connect repository'**
  String get connectRepository;

  /// No description provided for @skipGitSetup.
  ///
  /// In en, this message translates to:
  /// **'Skip for now — set up later in Settings'**
  String get skipGitSetup;

  /// No description provided for @onboardingLocalFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Local-first'**
  String get onboardingLocalFirstTitle;

  /// No description provided for @onboardingLocalFirstDesc.
  ///
  /// In en, this message translates to:
  /// **'Your notes live on your device as plain .md files. No cloud lock-in, no subscriptions.'**
  String get onboardingLocalFirstDesc;

  /// No description provided for @onboardingGitSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Git sync'**
  String get onboardingGitSyncTitle;

  /// No description provided for @onboardingGitSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync via your own GitHub or GitLab repo. You own the data, always.'**
  String get onboardingGitSyncDesc;

  /// No description provided for @onboardingDevTitle.
  ///
  /// In en, this message translates to:
  /// **'Built for developers'**
  String get onboardingDevTitle;

  /// No description provided for @onboardingDevDesc.
  ///
  /// In en, this message translates to:
  /// **'Markdown editing with syntax highlighting, code blocks, and a customizable toolbar.'**
  String get onboardingDevDesc;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @firstNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first note'**
  String get firstNoteTitle;

  /// No description provided for @firstNoteBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll create a sample note with a Markdown guide to get you started.'**
  String get firstNoteBody;

  /// No description provided for @firstNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Create & start'**
  String get firstNoteButton;

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve conflicts'**
  String get conflictTitle;

  /// No description provided for @conflictThisDevice.
  ///
  /// In en, this message translates to:
  /// **'this device'**
  String get conflictThisDevice;

  /// No description provided for @conflictRemote.
  ///
  /// In en, this message translates to:
  /// **'remote'**
  String get conflictRemote;

  /// No description provided for @conflictVersionOn.
  ///
  /// In en, this message translates to:
  /// **'{side} VERSION'**
  String conflictVersionOn(String side);

  /// No description provided for @conflictKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep {side} version'**
  String conflictKeep(String side);

  /// No description provided for @conflictKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get conflictKeepBoth;

  /// No description provided for @conflictResolveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t resolve the conflict: {error}'**
  String conflictResolveFailed(String error);

  /// No description provided for @conflictRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conflicting note left.} other{{count} conflicting notes left.}}'**
  String conflictRemaining(int count);

  /// No description provided for @conflictAllResolved.
  ///
  /// In en, this message translates to:
  /// **'All conflicts resolved — tap Sync to finish.'**
  String get conflictAllResolved;

  /// No description provided for @conflictReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file: {error}'**
  String conflictReadFailed(String error);

  /// No description provided for @conflictNoMarkers.
  ///
  /// In en, this message translates to:
  /// **'This file no longer has conflict markers — it looks like it was fixed by hand.'**
  String get conflictNoMarkers;

  /// No description provided for @conflictMarkResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark as resolved'**
  String get conflictMarkResolved;

  /// No description provided for @syncHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync history'**
  String get syncHistoryTitle;

  /// No description provided for @syncHistoryLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date}'**
  String syncHistoryLastSync(String date);

  /// No description provided for @syncHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sync history yet'**
  String get syncHistoryEmpty;

  /// No description provided for @syncHistoryEntry.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{action} — 1 file} other{{action} — {count} files}}'**
  String syncHistoryEntry(String action, int count);

  /// No description provided for @editorToolFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get editorToolFont;

  /// No description provided for @editorToolSizeDown.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get editorToolSizeDown;

  /// No description provided for @editorToolSizeUp.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get editorToolSizeUp;

  /// No description provided for @editorToolLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get editorToolLineHeight;

  /// No description provided for @editorToolWordWrap.
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get editorToolWordWrap;

  /// No description provided for @editorToolFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get editorToolFocusMode;

  /// No description provided for @editorToolTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get editorToolTheme;

  /// No description provided for @editorToolUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get editorToolUndo;

  /// No description provided for @editorToolRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get editorToolRedo;

  /// No description provided for @editorToolIndent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get editorToolIndent;

  /// No description provided for @editorToolOutdent.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get editorToolOutdent;

  /// No description provided for @editorToolMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move line up'**
  String get editorToolMoveUp;

  /// No description provided for @editorToolMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move line down'**
  String get editorToolMoveDown;

  /// No description provided for @editorToolDuplicateLine.
  ///
  /// In en, this message translates to:
  /// **'Duplicate line'**
  String get editorToolDuplicateLine;

  /// No description provided for @editorToolDeleteLine.
  ///
  /// In en, this message translates to:
  /// **'Delete line'**
  String get editorToolDeleteLine;

  /// No description provided for @editorToolFindReplace.
  ///
  /// In en, this message translates to:
  /// **'Find & replace'**
  String get editorToolFindReplace;

  /// No description provided for @editorToolDateTime.
  ///
  /// In en, this message translates to:
  /// **'Insert date & time'**
  String get editorToolDateTime;

  /// No description provided for @editorToolSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get editorToolSymbols;

  /// No description provided for @editorToolNoteLink.
  ///
  /// In en, this message translates to:
  /// **'Note link'**
  String get editorToolNoteLink;

  /// No description provided for @editorToolTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get editorToolTemplate;

  /// No description provided for @editorToolOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get editorToolOutline;

  /// No description provided for @editorToolStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get editorToolStats;

  /// No description provided for @editorToolsButton.
  ///
  /// In en, this message translates to:
  /// **'Editor tools'**
  String get editorToolsButton;

  /// No description provided for @editorToolGroupDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get editorToolGroupDisplay;

  /// No description provided for @editorToolGroupEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorToolGroupEdit;

  /// No description provided for @editorToolGroupInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get editorToolGroupInsert;

  /// No description provided for @editorToolGroupView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get editorToolGroupView;

  /// No description provided for @editorToolGroupFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get editorToolGroupFormat;

  /// No description provided for @editorFontSystem.
  ///
  /// In en, this message translates to:
  /// **'System font'**
  String get editorFontSystem;

  /// No description provided for @lineHeightCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get lineHeightCompact;

  /// No description provided for @lineHeightNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get lineHeightNormal;

  /// No description provided for @lineHeightRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get lineHeightRelaxed;

  /// No description provided for @editorToolsCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get editorToolsCustomize;

  /// No description provided for @editorToolsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get editorToolsDone;

  /// No description provided for @editorToolsPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get editorToolsPin;

  /// No description provided for @editorToolsShowInSheet.
  ///
  /// In en, this message translates to:
  /// **'Show in sheet'**
  String get editorToolsShowInSheet;

  /// No description provided for @editorToolsCustomizeHint.
  ///
  /// In en, this message translates to:
  /// **'Pin a tool to the toolbar, or hide it from this sheet. Hidden tools stay listed here so you can bring them back.'**
  String get editorToolsCustomizeHint;

  /// No description provided for @findQueryHint.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findQueryHint;

  /// No description provided for @findReplacementHint.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get findReplacementHint;

  /// No description provided for @findPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get findPrevious;

  /// No description provided for @findNext.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get findNext;

  /// No description provided for @findReplaceOne.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get findReplaceOne;

  /// No description provided for @findReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get findReplaceAll;

  /// No description provided for @findClose.
  ///
  /// In en, this message translates to:
  /// **'Close find'**
  String get findClose;

  /// No description provided for @tablePickerColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get tablePickerColumns;

  /// No description provided for @tablePickerRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get tablePickerRows;

  /// No description provided for @tablePickerInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get tablePickerInsert;

  /// No description provided for @tableColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Column {n}'**
  String tableColumnHeader(int n);

  /// No description provided for @codeLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Code block language'**
  String get codeLanguageTitle;

  /// No description provided for @templatePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Note templates'**
  String get templatePickerTitle;

  /// No description provided for @notePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a note to link'**
  String get notePickerTitle;

  /// No description provided for @notePickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other notes yet'**
  String get notePickerEmpty;

  /// No description provided for @noteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Note not found: {file}'**
  String noteNotFound(String file);

  /// No description provided for @noteLinksUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Renamed, but couldn\'t update links in: {files}'**
  String noteLinksUpdateFailed(String files);

  /// No description provided for @outlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get outlineTitle;

  /// No description provided for @outlineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No headings in this note'**
  String get outlineEmpty;

  /// No description provided for @editorStatsLine.
  ///
  /// In en, this message translates to:
  /// **'{words, plural, =1{1 word} other{{words} words}} · {chars, plural, =1{1 char} other{{chars} chars}}{minutes, plural, =0{} other{ · ~{minutes} min read}}'**
  String editorStatsLine(int words, int chars, int minutes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
