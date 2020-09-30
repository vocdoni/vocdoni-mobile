import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';

class LanguageSelect extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "title.language"),
      ),
      body: Builder(
          builder: (BuildContext context) => ListView(
                children: <Widget>[
                  // Section(text: getText(context, "main.availableLanguages")),
                  ListItem(
                      mainText: getText(context, "main.english"),
                      rightIcon:
                          Globals.appState.locale.value.languageCode == "en"
                              ? FeatherIcons.check
                              : FeatherIcons.globe,
                      onTap: () {
                        Globals.appState
                            .selectLocale(Locale("en"))
                            .then((_) => Navigator.of(context).pop(true));
                      }),
                  ListItem(
                      mainText: getText(context, "main.french"),
                      rightIcon:
                          Globals.appState.locale.value.languageCode == "fr"
                              ? FeatherIcons.check
                              : FeatherIcons.globe,
                      onTap: () {
                        Globals.appState
                            .selectLocale(Locale("fr"))
                            .then((_) => Navigator.of(context).pop(true));
                      }),
                  ListItem(
                      mainText: getText(context, "main.spanish"),
                      rightIcon:
                          Globals.appState.locale.value.languageCode == "es"
                              ? FeatherIcons.check
                              : FeatherIcons.globe,
                      onTap: () {
                        Globals.appState
                            .selectLocale(Locale("es"))
                            .then((_) => Navigator.of(context).pop(true));
                      }),
                  ListItem(
                      mainText: getText(context, "main.catalan"),
                      rightIcon:
                          Globals.appState.locale.value.languageCode == "ca"
                              ? FeatherIcons.check
                              : FeatherIcons.globe,
                      onTap: () {
                        Globals.appState
                            .selectLocale(Locale("ca"))
                            .then((_) => Navigator.of(context).pop(true));
                      })
                ],
              )),
    );
  }
}
