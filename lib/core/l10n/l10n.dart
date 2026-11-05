import 'package:flutter/widgets.dart';
import 'package:devnotes/l10n/app_localizations.dart';

export 'package:devnotes/l10n/app_localizations.dart';

/// Viết tắt cho `AppLocalizations.of(context)`.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
