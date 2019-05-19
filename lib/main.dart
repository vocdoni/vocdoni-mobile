import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vocdoni/views/identity-details.dart';
import 'package:vocdoni/views/identity-select.dart';
import 'package:vocdoni/views/organizations.dart';

import 'dart:async';
import 'util/singletons.dart';
import 'lang/index.dart';

import "views/welcome.dart";
import "views/welcome-identity.dart";
import "views/welcome-identity-create.dart";
import "views/welcome-identity-recover.dart";
import "views/home.dart";
import "views/identity-welcome.dart";

void main() async {
  // RESTORE DATA
  await appStateBloc.restore();
  await identitiesBloc.restore();
  await electionsBloc.restore();
  await newsFeedsBloc.restore();

  // POST RENDER TRIGGERS
  Timer(Duration(seconds: 5), () async {
    await appStateBloc.loadBootNodes();
  });

  // DETERMINE THE FIRST SCREEN
  Widget home;
  if (identitiesBloc?.current?.length > 0) {
    home = IdentitySelect();
  } else {
    home = IdentityWelcome();
  }

  // RUN THE APP
  runApp(MaterialApp(
    title: 'Vocdoni',
    localizationsDelegates: [
      LangDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate
    ],
    supportedLocales: [Locale("en"), Locale("fr"), Locale("ca"), Locale("es")],
    onGenerateTitle: (BuildContext context) => Lang.of(context).get("Vocdoni"),
    home: home,
    routes: {
      // NO IDENTITIES YET
      "/identityWelcome": (context) => IdentityWelcome(),
      "/welcome": (context) => WelcomeScreen(),
      "/welcome/identity": (context) => WelcomeIdentityScreen(),
      "/welcome/identity/create": (context) => WelcomeIdentityCreateScreen(),
      "/welcome/identity/recover": (context) => WelcomeIdentityRecoverScreen(),

      // IDENTITY/IES AVAILABLE
      "/home": (context) => HomeScreen(),
      "/organizations": (context) => Organizations(),
      "/identityDetails": (context) => IdentityDetails(),
    },
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}
