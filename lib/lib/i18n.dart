// INFO: https://medium.com/flutter-community/flutter-internationalization-the-easy-way-using-provider-and-json-c47caa4212b2

import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'dart:convert';

const SUPPORTED_LANGUAGES = <String>["en", "fr", "es", "ca"];
const DEFAULT_LANGUAGE = "en";

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings;
  Map<String, String> _defaultStrings;

  AppLocalizations(this.locale);

  /// Helper method to keep the code in the widgets concise
  /// Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<void> load() async {
    // Load the strings of the default language
    if (_defaultStrings == null) {
      final defaultStrings =
          await rootBundle.loadString('assets/i18n/$DEFAULT_LANGUAGE.json');
      final Map<String, dynamic> defaultStringMap = json.decode(defaultStrings);

      _defaultStrings = defaultStringMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
    }

    // Load the strings of the current language
    if (locale.languageCode != DEFAULT_LANGUAGE) {
      final langStrings = await rootBundle
          .loadString('assets/i18n/${locale.languageCode}.json');
      final Map<String, dynamic> stringMap = json.decode(langStrings);

      _localizedStrings = stringMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
    } else {
      _localizedStrings = _defaultStrings;
    }
  }

  /// This method will be called from every widget which needs a localized text.
  /// If a string is missing on the current language, the default language will be used.
  String translate(String key) {
    if (_localizedStrings[key] is String && _localizedStrings[key].length > 0) {
      return _localizedStrings[key];
    } else if (_defaultStrings[key] is String &&
        _defaultStrings[key].length > 0) {
      if (!kReleaseMode)
        print("Translation [${locale.languageCode}] not found: $key");
      return _defaultStrings[key];
    }
    if (!kReleaseMode) print("No translations found: $key");
    return key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  /// This delegate instance will never change (it doesn't even have fields!)
  /// It can provide a constant constructor.
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return SUPPORTED_LANGUAGES.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = new AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Returns the given key translated into the currently active language on the given context.
/// Alias of `AppLocalizations.of(ctx).translate(key);`
String getText(BuildContext context, String key) {
  return AppLocalizations.of(context).translate(key);
}
