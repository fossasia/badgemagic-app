import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';

/// Global localization holder to provide AppLocalizations without BuildContext.
class LocalizationService {
  AppLocalizations? _l10n;
  static const String _localeFileName = '.locale';

  AppLocalizations get l10n {
    final current = _l10n;
    if (current == null) {
      throw StateError('LocalizationService not initialized');
    }
    return current;
  }

  Future<void> init(Locale locale) async {
    _l10n = await AppLocalizations.delegate.load(locale);
  }

  Future<void> updateLocale(Locale locale) async {
    _l10n = await AppLocalizations.delegate.load(locale);
  }

  Future<File> _getLocaleFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localeFileName');
  }

  Future<Locale?> loadSavedLocale() async {
    try {
      final file = await _getLocaleFile();
      if (await file.exists()) {
        final code = (await file.readAsString()).trim();
        if (code.isNotEmpty) {
          return Locale(code);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveLocale(Locale locale) async {
    try {
      final file = await _getLocaleFile();
      await file.writeAsString(locale.languageCode);
    } catch (_) {}
  }
}
