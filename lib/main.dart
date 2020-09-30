import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/views/dev/dev-analytics-tests.dart';
import 'package:vocdoni/views/dev/dev-pager.dart';
import 'package:vocdoni/views/dev/dev-ui-avatar-color.dart';
import 'package:vocdoni/views/dev/dev-ui-card.dart';
import 'package:vocdoni/views/dev/dev-ui-listItem.dart';
import 'package:vocdoni/views/entity-feed-page.dart';
import 'package:vocdoni/views/entity-participation-page.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/views/identity-restore-page.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'package:vocdoni/views/startup-page.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/identity-select-page.dart';
import "package:vocdoni/views/identity-create-page.dart";
import 'package:vocdoni/views/identity-backup-page.dart';
import 'package:vocdoni/views/entity-page.dart';
import 'package:vocdoni/views/dev/dev-menu.dart';
import 'package:eventual/eventual-builder.dart';
// import 'package:vocdoni/view-modals/sign-modal.dart';
import "views/home.dart";

/// The actual main function is defined on main-dev.dart and main-production.dart.
/// These are expected to call mainCommon() when done
void main() async {
  // If you're running an application and need to access the binary messenger before `runApp()`
  // has been called (for example, during plugin initialization), then you need to explicitly
  // call the `WidgetsFlutterBinding.ensureInitialized()` first.
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // RUN THE APP
  runApp(buildMainContainer());
}

Widget buildMainContainer() {
  return EventualBuilder(
    notifier: Globals.appState.locale,
    builder: (BuildContext ctx, _, __) {
      return buildMainApp();
    },
  );
}

Widget buildMainApp() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Vocdoni",
    locale: Globals.appState.locale.value,
    supportedLocales:
        SUPPORTED_LANGUAGES.map((loc) => Locale(loc)).cast<Locale>().toList(),
    localizationsDelegates: [
      AppLocalization.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    onGenerateTitle: (BuildContext context) => "Vocdoni",
    home: StartupPage(),
    navigatorKey: Globals
        .navigatorKey, // Allows the logic to navigate without a build context
    onGenerateRoute: generateRoute,
    routes: {
      // NO ACCOUNT SELECTED YET
      "/identity/create": (context) => IdentityCreatePage(),
      "/identity/restore": (context) => IdentityRestorePage(),
      "/identity/select": (context) => IdentitySelectPage(),

      // WHEN THERE IS AN ACCOUNT
      "/home": (context) => HomeScreen(),
      "/entity/feed": (context) => EntityFeedPage(),
      "/entity/feed/post": (context) => FeedPostPage(),
      "/entity/participation": (context) => EntityParticipationPage(),
      "/entity/participation/poll": (context) => PollPage(),
      "/identity/backup": (context) => IdentityBackupPage(),

      // GLOBAL
      // "/web/viewer": (context) => WebViewer(),
      // "/signature": (context) => SignModal(),

      // DEV
      "/dev": (context) => DevMenu(),
      "/dev/ui-listItem": (context) => DevUiListItem(),
      "/dev/ui-card": (context) => DevUiCard(),
      "/dev/ui-avatar-colors": (context) => DevUiAvatarColor(),
      "/dev/analytics-tests": (context) => AnalyticsTests(),
      "/dev/pager": (context) => DevPager(),
    },
    theme: ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: "Open Sans",
      scaffoldBackgroundColor: colorBaseBackground,
    ),
  );
}

// generateRoute is called when nothing is found on `routes`
Route<dynamic> generateRoute(RouteSettings settings) {
  return MaterialPageRoute(builder: (_) {
    switch (settings.name) {
      // VIEWS
      case '/entity':
        if (settings.arguments is! EntityModel)
          throw Exception("settings.arguments must be of type EntityModel");
        return EntityInfoPage(settings.arguments);
      default:
        return null;
    }
  });
}
