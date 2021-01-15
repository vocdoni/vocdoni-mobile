// INFO: https://medium.com/flutter-community/flutter-internationalization-the-easy-way-using-provider-and-json-c47caa4212b2

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// eo is supported by the app but not supported by Flutter
const SUPPORTED_LANGUAGES = <String>["en", "fr", "es", "ca", "nb", "pt"];
const DEFAULT_LANGUAGE = "en";

class AppLocalization {
  Locale _locale;
  Map<String, String> _localizedStrings;
  Map<String, String> _defaultStrings;

  Locale get locale => _locale;

  AppLocalization(this._locale, this._localizedStrings, [this._defaultStrings]);

  /// Helper method to keep the code in the widgets concise
  /// Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  /// Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalizationDelegate();

  static Future<AppLocalization> load([Locale newLocale]) async {
    Locale locale;
    Map<String, String> defaultStrings;
    Map<String, String> localizedStrings;

    // Update the locale is a specific one is passed
    if (newLocale != null) {
      locale = newLocale;
    }

    // Load the strings of the default language
    if (defaultStrings == null) {
      final jsonDefaultStrings =
          await rootBundle.loadString('assets/i18n/$DEFAULT_LANGUAGE.json');
      final Map<String, dynamic> defaultStringMap =
          json.decode(jsonDefaultStrings);

      defaultStrings = defaultStringMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
    }

    // Load the strings of the current language

    if (locale.languageCode == DEFAULT_LANGUAGE) {
      localizedStrings = defaultStrings;
      return AppLocalization(locale, localizedStrings, defaultStrings);
    }

    final code = locale.languageCode.substring(0, 2);
    final langStrings = await rootBundle.loadString('assets/i18n/$code.json');
    final Map<String, dynamic> stringMap = json.decode(langStrings);

    localizedStrings = stringMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return AppLocalization(locale, localizedStrings, defaultStrings);
  }

  /// This method will be called from every widget which needs a localized text.
  /// If a string is missing on the current language, the default language will be used.
  String translate(String key) {
    if (_localizedStrings[key] is String && _localizedStrings[key].length > 0) {
      return _localizedStrings[key];
    } else if (_defaultStrings[key] is String &&
        _defaultStrings[key].length > 0) {
      if (!kReleaseMode)
        print("Translation [${_locale.languageCode}] not found: $key");
      return _defaultStrings[key];
    }
    if (!kReleaseMode) print("No translations found: $key");
    return key;
  }
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  /// This delegate instance will never change (it doesn't even have fields!)
  /// It can provide a constant constructor.
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return SUPPORTED_LANGUAGES.contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) {
    // AppLocalization class is where the JSON loading actually runs
    return AppLocalization.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => false;
}

/// Returns the given key translated into the currently active language on the given context.
/// Alias of `AppLocalization.of(ctx).translate(key);`
String getText(BuildContext context, String key) {
  return AppLocalization.of(context).translate(key);
}

extension Translatable on String {
  /// Returns the given key translated into the currently active language on the given context.
  /// Alias of `AppLocalization.of(ctx).translate(originalString);`
  String translate(BuildContext context) {
    return AppLocalization.of(context).translate(this);
  }
}
