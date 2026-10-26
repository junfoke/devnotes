// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonCreate => 'Tạo';

  @override
  String get commonEdit => 'Sửa';

  @override
  String get commonRename => 'Đổi tên';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonSkip => 'Bỏ qua';

  @override
  String get untitled => 'Không có tiêu đề';

  @override
  String get unknownError => 'Lỗi không xác định';

  @override
  String errorWithDetail(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get gitBusy => 'Đang đồng bộ, thử lại sau khi xong.';

  @override
  String get unresolvedConflictsBeforeSwitch =>
      'Còn conflict chưa giải quyết — giải quyết xong rồi mới chuyển branch.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsSectionGit => 'Git';

  @override
  String get settingsGitRepository => 'Git repository';

  @override
  String get settingsSectionSync => 'Đồng bộ';

  @override
  String get settingsSyncFrequency => 'Tần suất đồng bộ';

  @override
  String get settingsSectionEditor => 'Trình soạn thảo';

  @override
  String get settingsFontAndSize => 'Font & cỡ chữ';

  @override
  String get settingsToolbarLayout => 'Bố cục thanh công cụ';

  @override
  String get settingsSectionAppearance => 'Giao diện';

  @override
  String get settingsTheme => 'Chủ đề màu';

  @override
  String get settingsThemeTooltip => 'Chọn chủ đề màu';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageTooltip => 'Chọn ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsSectionData => 'Dữ liệu';

  @override
  String get settingsExportNotes => 'Xuất ghi chú';

  @override
  String get settingsExportSubject => 'Bản xuất DevNotes';

  @override
  String settingsExportFailed(String error) {
    return 'Xuất thất bại: $error';
  }

  @override
  String get settingsImportNotes => 'Nhập ghi chú';

  @override
  String get settingsRebuildIndex => 'Dựng lại chỉ mục tìm kiếm';

  @override
  String get settingsSectionCollections => 'Collection';

  @override
  String get settingsManageCollections => 'Quản lý collection';

  @override
  String get settingsSectionAbout => 'Thông tin ứng dụng';

  @override
  String get settingsAboutTagline => 'Ghi chú Markdown local-first cho dev';

  @override
  String settingsSaveFailed(String error) {
    return 'Không lưu được cài đặt: $error';
  }

  @override
  String importFailed(String error) {
    return 'Nhập thất bại: $error';
  }

  @override
  String importInvalidZip(String error) {
    return 'File không phải ZIP hợp lệ: $error';
  }

  @override
  String get importDoneTitle => 'Đã nhập ghi chú';

  @override
  String importAdded(int count) {
    return 'Thêm mới: $count';
  }

  @override
  String importSkippedIdentical(int count) {
    return 'Bỏ qua vì đã có y hệt: $count';
  }

  @override
  String importCopied(int count) {
    return 'Trùng tên nên lưu thành bản sao: $count';
  }

  @override
  String importRejected(int count) {
    return 'Từ chối (đường dẫn không an toàn): $count';
  }

  @override
  String get rebuildIndexInProgress => 'Đang dựng lại chỉ mục tìm kiếm...';

  @override
  String rebuildIndexDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã dựng lại chỉ mục cho $count ghi chú',
    );
    return '$_temp0';
  }

  @override
  String rebuildIndexFailed(String error) {
    return 'Dựng lại chỉ mục thất bại: $error';
  }

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get fontPreviewSample => '## Xem trước\nconst answer = 42; // **đậm**';

  @override
  String get toolbarLayoutHint =>
      'Ghim công cụ lên thanh công cụ, ẩn khỏi bảng ⋯, và kéo mục đã ghim để đổi thứ tự. Thay đổi áp dụng ngay cho editor.';

  @override
  String get toolbarLayoutPinnedTitle => 'Đã ghim trên thanh công cụ';

  @override
  String get toolbarLayoutOthersTitle => 'Chưa ghim';

  @override
  String get toolbarItemH1 => 'Tiêu đề 1';

  @override
  String get toolbarItemH2 => 'Tiêu đề 2';

  @override
  String get toolbarItemH3 => 'Tiêu đề 3';

  @override
  String get toolbarItemBold => 'In đậm';

  @override
  String get toolbarItemItalic => 'In nghiêng';

  @override
  String get toolbarItemStrikethrough => 'Gạch ngang';

  @override
  String get toolbarItemLink => 'Liên kết';

  @override
  String get toolbarItemImage => 'Hình ảnh';

  @override
  String get toolbarItemCodeInline => 'Code trong dòng';

  @override
  String get toolbarItemCodeBlock => 'Khối code';

  @override
  String get toolbarItemChecklist => 'Danh sách việc';

  @override
  String get toolbarItemListUnordered => 'Danh sách gạch đầu dòng';

  @override
  String get toolbarItemListOrdered => 'Danh sách đánh số';

  @override
  String get toolbarItemQuote => 'Trích dẫn';

  @override
  String get toolbarItemTable => 'Bảng';

  @override
  String get toolbarItemHr => 'Đường kẻ ngang';

  @override
  String get syncFrequencyManual => 'Thủ công';

  @override
  String get syncFrequencyManualDesc => 'Chỉ đồng bộ khi bấm nút Đồng bộ.';

  @override
  String get syncFrequencyOnOpen => 'Khi mở app';

  @override
  String get syncFrequencyOnOpenDesc =>
      'Tự đồng bộ khi mở app và khi quay lại app (cách nhau ít nhất 5 phút).';

  @override
  String get syncFrequencyPeriodic => 'Định kỳ';

  @override
  String get syncFrequencyPeriodicDesc =>
      'Như \"Khi mở app\", thêm đồng bộ định kỳ trong lúc app đang mở.';

  @override
  String syncFrequencyMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get syncFrequencyFootnote =>
      'App không đồng bộ ngầm khi đã đóng. Đồng bộ tự động gặp lỗi hoặc xung đột sẽ báo ở chấm trạng thái cạnh nút Đồng bộ.';

  @override
  String get tooltipSearchTitle => 'Tìm kiếm';

  @override
  String get tooltipSearchDesc => 'Tìm toàn văn trong tất cả ghi chú của bạn.';

  @override
  String get tooltipSyncTitle => 'Đồng bộ';

  @override
  String get tooltipSyncDesc =>
      'Chạm để đồng bộ ghi chú với Git repository của bạn.';

  @override
  String get tooltipNewNoteDesc => 'Tạo một ghi chú Markdown mới.';

  @override
  String get tooltipToolbarTitle => 'Thanh công cụ Markdown';

  @override
  String get tooltipToolbarDesc =>
      'Chèn nhanh cú pháp Markdown — tiêu đề, in đậm, khối code và nhiều hơn nữa.';

  @override
  String get tooltipPreviewTitle => 'Vuốt để xem trước';

  @override
  String get tooltipPreviewDesc =>
      'Vuốt sang trái để xem Markdown đã hiển thị.';

  @override
  String get newNote => 'Ghi chú mới';

  @override
  String noteDeleteFailed(String error) {
    return 'Không xóa được ghi chú: $error';
  }

  @override
  String noteCreateFailed(String error) {
    return 'Không tạo được ghi chú: $error';
  }

  @override
  String noteRenameFailed(String error) {
    return 'Không đổi được tên: $error';
  }

  @override
  String collectionCreateFailed(String error) {
    return 'Không tạo được collection: $error';
  }

  @override
  String collectionEditFailed(String error) {
    return 'Không sửa được collection: $error';
  }

  @override
  String collectionDeleteFailed(String error) {
    return 'Không xóa được collection: $error';
  }

  @override
  String syncHistoryLoadFailed(String error) {
    return 'Không đọc được lịch sử đồng bộ: $error';
  }

  @override
  String get deleteNoteTitle => 'Xóa ghi chú';

  @override
  String deleteNoteConfirm(String title) {
    return 'Xóa \"$title\"? Không thể hoàn tác.';
  }

  @override
  String get syncAlreadyRunning => 'Đang đồng bộ, chờ lần hiện tại xong đã.';

  @override
  String syncError(String error) {
    return 'Lỗi đồng bộ: $error';
  }

  @override
  String syncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đồng bộ — $count file thay đổi',
    );
    return '$_temp0';
  }

  @override
  String syncFailed(String error) {
    return 'Đồng bộ thất bại: $error';
  }

  @override
  String get searchNoResults => 'Không tìm thấy kết quả';

  @override
  String searchError(String error) {
    return 'Lỗi tìm kiếm: $error';
  }

  @override
  String get collectionNoNotes => 'Không có ghi chú nào trong collection này';

  @override
  String get collectionShowAll => 'Xem tất cả ghi chú';

  @override
  String noteListLoadFailed(String error) {
    return 'Không tải được danh sách ghi chú: $error';
  }

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String get searchHint => 'Tìm ghi chú...';

  @override
  String get searchClearTooltip => 'Xóa từ khóa';

  @override
  String get emptyNotesTitle => 'Chưa có ghi chú nào';

  @override
  String get emptyNotesSubtitle => 'Tạo ghi chú đầu tiên để bắt đầu';

  @override
  String get emptyNotesButton => 'Tạo ghi chú đầu tiên';

  @override
  String get timeJustNow => 'vừa xong';

  @override
  String timeMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get allNotes => 'Tất cả ghi chú';

  @override
  String get noteTitleHint => 'Tiêu đề ghi chú';

  @override
  String get tagsHint => 'Tag (cách nhau bằng dấu phẩy)';

  @override
  String get titleRequired => 'Vui lòng nhập tiêu đề';

  @override
  String get titleMustDiffer => 'Tiêu đề mới phải khác tiêu đề hiện tại';

  @override
  String get renameNoteTitle => 'Đổi tên ghi chú';

  @override
  String get newTitleHint => 'Tiêu đề mới';

  @override
  String get newCollectionTitle => 'Collection mới';

  @override
  String get editCollectionTitle => 'Sửa collection';

  @override
  String get collectionNameHint => 'Tên collection';

  @override
  String get filterTagsHint => 'Tag để lọc (cách nhau bằng dấu phẩy)';

  @override
  String deleteCollectionTitle(String name) {
    return 'Xóa collection \"$name\"?';
  }

  @override
  String get deleteCollectionBody =>
      'Chỉ xóa nhóm. Các ghi chú bên trong vẫn giữ nguyên trong Tất cả ghi chú.';

  @override
  String get collectionsEmpty =>
      'Chưa có collection nào.\nTạo bằng nút + ở màn hình chính.';

  @override
  String noteSaveFailed(String error) {
    return 'Không lưu được ghi chú: $error';
  }

  @override
  String noteOpenFailed(String error) {
    return 'Không mở được ghi chú: $error';
  }

  @override
  String get externalChangeTitle => 'Ghi chú đã thay đổi bên ngoài';

  @override
  String get externalChangeBody =>
      'Trong lúc bạn đang sửa, ghi chú này vừa được thay đổi ở nơi khác (ví dụ do đồng bộ). Để không ghi đè mất bản đó, hãy chọn:';

  @override
  String get externalChangeReload => 'Tải bản mới';

  @override
  String get externalChangeKeepMine => 'Lưu bản của tôi thành note mới';

  @override
  String editedCopyTitle(String title) {
    return '$title (bản sửa)';
  }

  @override
  String savedAsCopy(String title) {
    return 'Đã lưu bản của bạn thành \"$title\".';
  }

  @override
  String copySaveFailed(String error) {
    return 'Không lưu được bản sao: $error';
  }

  @override
  String get editorMenuShare => 'Chia sẻ';

  @override
  String get editorMenuEditTags => 'Sửa tag';

  @override
  String get editorMenuInfo => 'Thông tin';

  @override
  String shareFailed(String error) {
    return 'Không chia sẻ được: $error';
  }

  @override
  String noteInfoFile(String name) {
    return 'File: $name';
  }

  @override
  String noteInfoTags(String tags) {
    return 'Tag: $tags';
  }

  @override
  String noteInfoCreated(String date) {
    return 'Tạo lúc: $date';
  }

  @override
  String noteInfoUpdated(String date) {
    return 'Sửa lúc: $date';
  }

  @override
  String noteInfoWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count từ',
    );
    return '$_temp0';
  }

  @override
  String noteInfoChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ký tự',
    );
    return '$_temp0';
  }

  @override
  String get editorHint => 'Bắt đầu viết...';

  @override
  String get editTagsHint => 'Các tag, cách nhau bằng dấu phẩy';

  @override
  String linkOpenFailed(String url) {
    return 'Không mở được liên kết: $url';
  }

  @override
  String get gitSetupTitle => 'Thiết lập Git';

  @override
  String gitConfigLoadFailed(String error) {
    return 'Không đọc được cấu hình Git: $error';
  }

  @override
  String gitConfigSaveFailed(String error) {
    return 'Không lưu được cấu hình Git: $error';
  }

  @override
  String gitConfigDeleteFailed(String error) {
    return 'Không xóa được cấu hình Git: $error';
  }

  @override
  String get gitMissingFieldsCheck =>
      'Cần nhập đủ URL, username và PAT trước khi kiểm tra.';

  @override
  String get gitMissingFieldsSave => 'Cần nhập đủ URL, username và PAT để lưu.';

  @override
  String get gitMissingFieldsConnect =>
      'Cần nhập đủ URL, username và PAT để kết nối.';

  @override
  String get gitCredentialsSaved => 'Đã lưu thông tin đăng nhập Git';

  @override
  String get gitCredentialsRemoved => 'Đã xóa thông tin đăng nhập Git';

  @override
  String get disconnectRepository => 'Ngắt kết nối repository';

  @override
  String get disconnectBody =>
      'Thông tin đăng nhập Git đã lưu sẽ bị xóa. Ghi chú trên máy không bị ảnh hưởng.';

  @override
  String get disconnectButton => 'Ngắt kết nối';

  @override
  String get branchMismatchTitle => 'Branch không khớp cấu hình';

  @override
  String branchMismatchBody(String local, String configured) {
    return 'Ghi chú trên máy đang ở branch \"$local\", nhưng cấu hình là \"$configured\". Đồng bộ hiện đang đẩy lên \"$local\".';
  }

  @override
  String switchToBranch(String branch) {
    return 'Chuyển sang \"$branch\"';
  }

  @override
  String switchBranchConfirmTitle(String branch) {
    return 'Chuyển sang \"$branch\"?';
  }

  @override
  String switchBranchConfirmBody(String from, String to) {
    return 'Ghi chú của \"$from\" sẽ được gộp vào \"$to\" rồi đẩy lên remote. Không note nào bị xóa; branch \"$from\" vẫn được giữ lại làm bản dự phòng.\n\nNếu cùng một note bị sửa khác nhau ở hai branch, bạn sẽ được chuyển tới màn hình giải quyết xung đột.';
  }

  @override
  String get switchBranchButton => 'Chuyển';

  @override
  String switchedWithConflicts(String branch, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Đã chuyển sang \"$branch\", còn $count note xung đột. Giải quyết xong rồi bấm Đồng bộ.',
    );
    return '$_temp0';
  }

  @override
  String switchedAndPushed(String branch) {
    return 'Đã chuyển sang \"$branch\" và đẩy lên remote.';
  }

  @override
  String switchedNotPushed(String branch, String error) {
    return 'Đã chuyển sang \"$branch\" nhưng chưa đẩy lên được ($error). Lần đồng bộ sau sẽ đẩy.';
  }

  @override
  String switchBranchFailed(String error) {
    return 'Chuyển branch thất bại: $error';
  }

  @override
  String get repoConfigured => 'Đã cấu hình repository';

  @override
  String get gitSetupIntro =>
      'Kết nối Git repository riêng của bạn để đồng bộ ghi chú giữa các thiết bị. Dữ liệu luôn nằm trong tay bạn.';

  @override
  String get gitFieldRemoteUrl => 'URL Git remote';

  @override
  String get gitFieldUsername => 'Username';

  @override
  String get gitFieldPat => 'Personal access token (PAT)';

  @override
  String get gitFieldBranch => 'Branch';

  @override
  String get securityTitle => 'Dữ liệu của bạn được bảo vệ';

  @override
  String get securityBody =>
      'Thông tin đăng nhập được lưu trên máy bạn, trong vùng lưu trữ đã mã hóa.';

  @override
  String get checkingConnection => 'Đang kiểm tra…';

  @override
  String get checkConnection => 'Kiểm tra kết nối';

  @override
  String get updateCredentials => 'Cập nhật thông tin đăng nhập';

  @override
  String get saveCredentials => 'Lưu thông tin đăng nhập';

  @override
  String remoteCheckOkEmpty(String branch) {
    return 'Kết nối thành công. Remote đang rỗng — lần đồng bộ đầu tiên sẽ đẩy ghi chú của bạn lên branch \"$branch\".';
  }

  @override
  String remoteCheckOkFound(String branch) {
    return 'Kết nối thành công. Đã thấy branch \"$branch\" trên remote.';
  }

  @override
  String get remoteCheckInvalidCredentials =>
      'Sai thông tin đăng nhập. Kiểm tra lại username và PAT — PAT có thể đã hết hạn hoặc thiếu quyền \"repo\".';

  @override
  String get remoteCheckRepoNotFound =>
      'Không tìm thấy repository. Kiểm tra lại URL. Nếu repo ở chế độ private thì PAT cũng phải có quyền truy cập chính repo đó.';

  @override
  String get remoteCheckNetworkUnreachable =>
      'Không ra được tới remote. Kiểm tra kết nối mạng rồi thử lại.';

  @override
  String remoteCheckBranchNotFound(String branch, String found) {
    return 'Kết nối được nhưng remote không có branch \"$branch\". Branch đang có: $found.';
  }

  @override
  String remoteCheckUnknown(String detail) {
    return 'Kiểm tra thất bại: $detail';
  }

  @override
  String get onboardingGitIntro =>
      'Kết nối Git repository riêng của bạn để đồng bộ ghi chú giữa các thiết bị. Bạn có thể thiết lập sau trong Cài đặt.';

  @override
  String get connectRepository => 'Kết nối repository';

  @override
  String get skipGitSetup => 'Bỏ qua — thiết lập sau trong Cài đặt';

  @override
  String get onboardingLocalFirstTitle => 'Local-first';

  @override
  String get onboardingLocalFirstDesc =>
      'Ghi chú nằm ngay trên máy bạn dưới dạng file .md thuần. Không bị khóa vào cloud, không thuê bao.';

  @override
  String get onboardingGitSyncTitle => 'Đồng bộ qua Git';

  @override
  String get onboardingGitSyncDesc =>
      'Đồng bộ qua repo GitHub hoặc GitLab của chính bạn. Dữ liệu luôn thuộc về bạn.';

  @override
  String get onboardingDevTitle => 'Dành cho lập trình viên';

  @override
  String get onboardingDevDesc =>
      'Soạn Markdown với tô màu cú pháp, khối code và thanh công cụ tùy chỉnh được.';

  @override
  String get onboardingNext => 'Tiếp';

  @override
  String get onboardingGetStarted => 'Bắt đầu';

  @override
  String get firstNoteTitle => 'Ghi chú đầu tiên';

  @override
  String get firstNoteBody =>
      'DevNotes sẽ tạo một ghi chú mẫu kèm hướng dẫn Markdown để bạn bắt đầu.';

  @override
  String get firstNoteButton => 'Tạo & bắt đầu';

  @override
  String get conflictTitle => 'Giải quyết xung đột';

  @override
  String get conflictThisDevice => 'máy này';

  @override
  String get conflictRemote => 'remote';

  @override
  String conflictVersionOn(String side) {
    return 'BẢN TRÊN $side';
  }

  @override
  String conflictKeep(String side) {
    return 'Giữ bản $side';
  }

  @override
  String get conflictKeepBoth => 'Giữ cả hai';

  @override
  String conflictResolveFailed(String error) {
    return 'Không giải quyết được xung đột: $error';
  }

  @override
  String conflictRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count note xung đột.',
    );
    return '$_temp0';
  }

  @override
  String get conflictAllResolved =>
      'Đã giải quyết hết xung đột — bấm Đồng bộ để hoàn tất.';

  @override
  String conflictReadFailed(String error) {
    return 'Không đọc được file: $error';
  }

  @override
  String get conflictNoMarkers =>
      'File này không còn dấu xung đột — có vẻ đã được sửa tay.';

  @override
  String get conflictMarkResolved => 'Đánh dấu đã giải quyết';

  @override
  String get syncHistoryTitle => 'Lịch sử đồng bộ';

  @override
  String syncHistoryLastSync(String date) {
    return 'Lần đồng bộ gần nhất: $date';
  }

  @override
  String get syncHistoryEmpty => 'Chưa có lịch sử đồng bộ';

  @override
  String syncHistoryEntry(String action, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$action — $count file',
    );
    return '$_temp0';
  }

  @override
  String get editorToolFont => 'Phông chữ';

  @override
  String get editorToolSizeDown => 'Giảm cỡ chữ';

  @override
  String get editorToolSizeUp => 'Tăng cỡ chữ';

  @override
  String get editorToolLineHeight => 'Giãn dòng';

  @override
  String get editorToolWordWrap => 'Tự xuống dòng';

  @override
  String get editorToolFocusMode => 'Chế độ tập trung';

  @override
  String get editorToolTheme => 'Giao diện';

  @override
  String get editorToolUndo => 'Hoàn tác';

  @override
  String get editorToolRedo => 'Làm lại';

  @override
  String get editorToolIndent => 'Thụt lề';

  @override
  String get editorToolOutdent => 'Lùi lề';

  @override
  String get editorToolMoveUp => 'Chuyển dòng lên';

  @override
  String get editorToolMoveDown => 'Chuyển dòng xuống';

  @override
  String get editorToolDuplicateLine => 'Nhân đôi dòng';

  @override
  String get editorToolDeleteLine => 'Xóa dòng';

  @override
  String get editorToolFindReplace => 'Tìm và thay';

  @override
  String get editorToolDateTime => 'Chèn ngày giờ';

  @override
  String get editorToolSymbols => 'Ký hiệu';

  @override
  String get editorToolNoteLink => 'Liên kết note';

  @override
  String get editorToolTemplate => 'Mẫu';

  @override
  String get editorToolOutline => 'Dàn ý';

  @override
  String get editorToolStats => 'Thống kê';

  @override
  String get editorToolsButton => 'Công cụ soạn thảo';

  @override
  String get editorToolGroupDisplay => 'Hiển thị';

  @override
  String get editorToolGroupEdit => 'Chỉnh sửa';

  @override
  String get editorToolGroupInsert => 'Chèn';

  @override
  String get editorToolGroupView => 'Xem';

  @override
  String get editorToolGroupFormat => 'Định dạng';

  @override
  String get editorFontSystem => 'Font hệ thống';

  @override
  String get lineHeightCompact => 'Gọn';

  @override
  String get lineHeightNormal => 'Vừa';

  @override
  String get lineHeightRelaxed => 'Thoáng';

  @override
  String get editorToolsCustomize => 'Tùy chỉnh';

  @override
  String get editorToolsDone => 'Xong';

  @override
  String get editorToolsPin => 'Ghim';

  @override
  String get editorToolsShowInSheet => 'Hiện trong bảng';

  @override
  String get editorToolsCustomizeHint =>
      'Ghim công cụ lên thanh công cụ, hoặc ẩn khỏi bảng này. Mục bị ẩn vẫn liệt kê ở đây để bật lại.';

  @override
  String get findQueryHint => 'Tìm';

  @override
  String get findReplacementHint => 'Thay bằng';

  @override
  String get findPrevious => 'Kết quả trước';

  @override
  String get findNext => 'Kết quả sau';

  @override
  String get findReplaceOne => 'Thay';

  @override
  String get findReplaceAll => 'Thay hết';

  @override
  String get findClose => 'Đóng tìm kiếm';

  @override
  String get tablePickerColumns => 'Số cột';

  @override
  String get tablePickerRows => 'Số hàng';

  @override
  String get tablePickerInsert => 'Chèn';

  @override
  String tableColumnHeader(int n) {
    return 'Cột $n';
  }

  @override
  String get codeLanguageTitle => 'Ngôn ngữ khối code';

  @override
  String get templatePickerTitle => 'Mẫu ghi chú';

  @override
  String get notePickerTitle => 'Chọn note để liên kết';

  @override
  String get notePickerEmpty => 'Chưa có note nào khác';

  @override
  String noteNotFound(String file) {
    return 'Không tìm thấy note: $file';
  }

  @override
  String noteLinksUpdateFailed(String files) {
    return 'Đã đổi tên, nhưng không sửa được link trong: $files';
  }

  @override
  String get outlineTitle => 'Mục lục';

  @override
  String get outlineEmpty => 'Note chưa có tiêu đề nào';

  @override
  String editorStatsLine(int words, int chars, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words từ',
    );
    return '$_temp0 · $chars ký tự · ~$minutes phút đọc';
  }
}
