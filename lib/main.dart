import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vocdoni/constants/colors.dart';
import 'lang/index.dart';
import 'util/singletons.dart';

import 'package:vocdoni/views/identity-select.dart';
import "package:vocdoni/views/identity-create.dart";
import 'package:vocdoni/views/identity-backup.dart';
import 'package:vocdoni/views/entity.dart';
import 'package:vocdoni/views/entity-activity.dart';
import 'package:vocdoni/views/activity-post.dart';
import 'package:vocdoni/modals/sign-modal.dart';
// import 'package:vocdoni/modals/web-viewer.dart';

// import "views/welcome-onboarding.dart";
import "views/home.dart";

void main() async {
  // RESTORE DATA
  await appStateBloc.init();
  await entitiesBloc.init();
  await identitiesBloc.init();
  await newsFeedsBloc.init();
  await processesBloc.init();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // DETERMINE THE FIRST SCREEN
  Widget home;
  if (identitiesBloc.current.length > 0 ?? false) {
    home = IdentitySelectScreen();
  } else {
    home = IdentityCreateScreen();
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
      "/identity/create": (context) => IdentityCreateScreen(),
      "/identity/select": (context) => IdentitySelectScreen(),

      // "/welcome": (context) => WelcomeOnboardingScreen(),  // ?
      // "/welcome/identity": (context) => WelcomeIdentityScreen(),
      // "/welcome/identity/create": (context) => WelcomeIdentityCreateScreen(),
      // "/welcome/identity/recover": (context) => WelcomeIdentityRecoverScreen(),

      // WHEN THERE IS AN IDENTITY
      "/home": (context) => HomeScreen(),
      "/entity": (context) => EntityInfo(),
      "/entity/activity": (context) => EntityActivity(),
      "/entity/activity/post": (context) => ActivityPostScreen(),
      "/identity/backup": (context) => IdentityBackupScreen(),

      // GLOBAL
      // "/web/viewer": (context) => WebViewer(),
      "/signature": (context) => SignModal(),
    },
    theme: ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: "Open Sans",
      scaffoldBackgroundColor: baseBackgroundColor,
    ),
  ));
}
