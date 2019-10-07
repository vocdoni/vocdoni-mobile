import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/views/dev-analytics-tests.dart';
import 'package:vocdoni/views/dev-ui-avatar-color.dart';
import 'package:vocdoni/views/dev-ui-card.dart';
import 'package:vocdoni/views/dev-ui-listItem.dart';
import 'package:vocdoni/views/entity-feed-page.dart';
import 'package:vocdoni/views/entity-participation-page.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'lang/index.dart';
import 'util/singletons.dart';
import 'package:vocdoni/views/identity-select-page.dart';
import "package:vocdoni/views/identity-create-page.dart";
import 'package:vocdoni/views/identity-backup-page.dart';
import 'package:vocdoni/views/entity-info-page.dart';
import 'package:vocdoni/views/dev-menu.dart';
import 'package:vocdoni/modals/sign-modal.dart';
import "views/home.dart";

void main() async {
  
  analytics.init();
  // RESTORE DATA
  await appStateBloc.init();
  await entitiesBloc.init();
  await identitiesBloc.init();
  await newsFeedsBloc.init();
  await processesBloc.init();

  await appStateBloc.load();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // DETERMINE THE FIRST SCREEN
  Widget home;
  if (identitiesBloc.value.length > 0 ?? false) {
    home = IdentitySelectPage();
  } else {
    home = IdentityCreatePage();
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
      "/identity/create": (context) => IdentityCreatePage(),
      "/identity/select": (context) => IdentitySelectPage(),

      // "/welcome": (context) => WelcomeOnboardingScreen(),  // ?
      // "/welcome/identity": (context) => WelcomeIdentityScreen(),
      // "/welcome/identity/create": (context) => WelcomeIdentityCreateScreen(),
      // "/welcome/identity/recover": (context) => WelcomeIdentityRecoverScreen(),

      // WHEN THERE IS AN IDENTITY
      "/home": (context) => HomeScreen(),
      "/entity": (context) => EntityInfoPage(),
      "/entity/feed": (context) => EntityFeedPage(),
      "/entity/feed/post": (context) => FeedPostPage(),
      "/entity/participation": (context) => EntityParticipationPage(),
      "/entity/participation/poll": (context) => PollPage(),
      "/identity/backup": (context) => IdentityBackupPage(),

      // GLOBAL
      // "/web/viewer": (context) => WebViewer(),
      "/signature": (context) => SignModal(),
      //DEV
      "/dev": (context) => DevMenu(),
      "/dev/ui-listItem": (context) => DevUiListItem(),
      "/dev/ui-card": (context) => DevUiCard(),
      "/dev/ui-avatar-colors":(context)=> DevUiAvatarColor(),
      "/dev/analytics-tests":(context)=> AnalyticsTests(),
    },
    theme: ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: "Open Sans",
      scaffoldBackgroundColor: colorBaseBackground,
    ),
  ));
}
