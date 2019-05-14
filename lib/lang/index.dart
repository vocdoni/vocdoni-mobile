// Useful resources:
// Current:   https://proandroiddev.com/flutter-localization-step-by-step-30f95d06018d
// AS Plugih: https://medium.com/@datvt9312/flutter-internationalization-tutorials-part-3-android-studio-plugin-8604e2dc90f0
// Hot swap:  https://github.com/datvo0110/flutter_i18n_plugin/blob/master/lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'messages_all.dart';

class Lang {
  static Future<Lang> load(Locale locale) {
    final String name =
        locale.countryCode == null ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return new Lang();
    });
  }

  static Lang of(BuildContext context) {
    return Localizations.of<Lang>(context, Lang);
  }

  // ///////////////////////////////////////////////////////////////////////////
  /// Helper method to allow Lang.of(context).get("My string goes here")
  /// as long as it is declared on _definitions()
  // ///////////////////////////////////////////////////////////////////////////

  String get(String key) {
    var _ = Intl.message; // avoid warnings of non-literals by aliasing
    return _(key);
  }

  /////////////////////////////////////////////////////////////////////////////
  // IMPORTANT:
  // DECLARE ANY STRINGS YOU USE IN THE METHOD BELOW
  // 
  // The code of this method is used so that Flutter can extract the string literals
  // No runtime functionality
  /////////////////////////////////////////////////////////////////////////////

  _definitions() {
    // GLOBAL
    Intl.message('Vocdoni');
    Intl.message('Welcome');

    // IDENTITY - ON BOARDING
    Intl.message('Create an identity');
    Intl.message('Import an identity');
    Intl.message('Create identity');
    Intl.message('Tap to create your self-sovereign identity');
    Intl.message('Your identity has been successfully created');

    // ERRORS
    Intl.message('An error occurred while generating the identity');
  }

  /////////////////////////////////////////////////////////////////////////////
  // DYNAMIC CONTENT CAN BE FETCHED HERE
  /////////////////////////////////////////////////////////////////////////////

  // String greetTo(String name) => Intl.message("Hello $name").replace(...);
}

class LangDelegate extends LocalizationsDelegate<Lang> {
  const LangDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'es', 'ca'].contains(locale.languageCode);
  }

  @override
  Future<Lang> load(Locale locale) {
    return Lang.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<Lang> old) {
    return false;
  }
}
