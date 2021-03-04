import 'dart:async';

import 'package:dvote_common/widgets/alerts.dart';
import 'package:dvote_common/widgets/loading-spinner.dart';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/analytics.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/notifications.dart';
import 'package:vocdoni/lib/startup.dart';
import 'package:vocdoni/view-modals/action-account-select.dart';
import '../lib/globals.dart';
import 'package:dvote_common/widgets/flavor-banner.dart';
import 'package:vocdoni/lib/extensions.dart';

class StartupPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool loading = true;
  String error;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 50)).then((_) => initApplication());
  }

  Future<void> initApplication() {
    if (!mounted) return Future.value();
    setState(() {
      loading = true;
      error = null;
    });

    return restorePersistence()
        .then((_) => restoreDataPools())
        // Depends on restorePersistence()
        .then((_) => Notifications.init())
        .then((_) => AppConfig.init())
        .then((_) => Globals.analytics.init())
        .then((_) => Globals.analytics.trackEvent(Events.APP_START))
        .then((_) {
      // non-blocking start networking
      startNetworking();
      showNextScreen();
      initLinking();

      // Detached update of the cached bootnodes
      Globals.appState.refresh().catchError(
          (err) => logger.log("[App] Detached bootnode update failed: $err"));
    }).catchError((err) {
      if (!mounted) return;
      logger.log(err);

      setState(() {
        loading = false;
        error = getText(context, "error.couldNotReadInternalData");
      });
      Globals.analytics.init();
      Globals.analytics.trackError("AppStartupError: $err");
      logger.log("AppStartupError: $err");

      // RETRY ITSELF
      Future.delayed(Duration(seconds: 10)).then((_) => initApplication());
    });
  }

  initLinking() async {
    // HANDLE APP LAUNCH LINK
    try {
      getInitialUri()
          .then((uri) =>
              handleLink(uri, context ?? Globals.navigatorKey.currentContext))
          .catchError((err) => handleIncomingLinkError(err));

      // HANDLE RUNTIME LINKS
      getUriLinksStream().listen(
          (uri) =>
              handleLink(uri, context ?? Globals.navigatorKey.currentContext),
          onError: handleIncomingLinkError);

      // Display the screen for a notification (if one is pending)
      Future.delayed(Duration(seconds: 1))
          .then((_) => Notifications.handlePendingNotification());
    } catch (err) {
      logger.log(err);
      showAlert(getText(context, "main.theLinkYouFollowedAppearsToBeInvalid"),
          title: getText(context, "main.error"), context: context);
    }
  }

  handleLink(Uri givenUri, BuildContext ctx) {
    if (givenUri == null || !Globals.accountPool.hasValue) return;
    if (Globals.accountPool.value.length == 1 ||
        givenUri.path.contains("recovery")) {
      handleIncomingLink(givenUri, ctx).catchError(handleIncomingLinkError);
    } else {
      Navigator.push(Globals.navigatorKey.currentContext,
              MaterialPageRoute(builder: (context) => LinkAccountSelect()))
          .then((result) {
        if (result != null && result is int) {
          Globals.appState.selectAccount(result);
          handleIncomingLink(givenUri, ctx).catchError(handleIncomingLinkError);
        }
      });
    }
  }

  handleIncomingLinkError(err) {
    logger.log(err?.toString() ?? "handleIncomingLinkError");
    final ctx = context ?? Globals.navigatorKey.currentContext;
    showAlert(getText(ctx, "error.thereWasAProblemHandlingTheLink"),
        title: getText(ctx, "main.error"), context: ctx);
  }

  void showNextScreen() {
    // Determine the next screen and go there
    String nextRoutePath;
    if (!Globals.accountPool.hasValue ||
        Globals.accountPool.value.length == 0) {
      nextRoutePath = "/onboarding-welcome";
    } else if (Globals.accountPool.value.length == 1) {
      Globals.appState.selectAccount(0);
      nextRoutePath = "/home";
    } else {
      nextRoutePath = "/identity/select";
    }

    // Replace all routes with /identity/select on top
    Navigator.pushNamedAndRemoveUntil(
        context, nextRoutePath, (Route _) => false);
  }

  Widget buildError(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 50),
        Image(
          image: AssetImage('assets/icon/icon-sm.png'),
          width: 80,
        ).withBottomPadding(10),
        Text("Vocdoni").withBottomPadding(60),
        Text(
          error ?? getText(context, "main.couldNotConnect"),
          style: new TextStyle(fontSize: 18, color: Color(0xff888888)),
          textAlign: TextAlign.center,
        ).withBottomPadding(10),
        InkWell(
            onTap: () => initApplication(),
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Text(
                  getText(context, "main.tapToRetry"),
                  style: TextStyle(fontSize: 16, color: Colors.black45),
                  textAlign: TextAlign.center,
                )))
      ],
    );
  }

  buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 50),
        Image(
          image: AssetImage('assets/icon/icon-sm.png'),
          width: 80,
        ).withBottomPadding(10),
        Text("Vocdoni").withBottomPadding(60),
        LoadingSpinner(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlavorBanner(
      mode: AppConfig.APP_MODE,
      child: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: Align(
              alignment: Alignment(0, -0.1),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 300, maxHeight: 350),
                  color: Color(0x00ff0000),
                  child: loading ? buildLoading() : buildError(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
