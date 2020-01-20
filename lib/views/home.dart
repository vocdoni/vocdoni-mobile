import 'dart:async';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/data-models/app-state.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/feed.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/views/home-tab.dart';
import 'package:vocdoni/views/entities-tab.dart';
import 'package:vocdoni/views/identity-tab.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:qrcode_reader/qrcode_reader.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int selectedTab = 0;

  /////////////////////////////////////////////////////////////////////////////
  // DEEP LINKS / UNIVERSAL LINKS
  /////////////////////////////////////////////////////////////////////////////

  StreamSubscription<Uri> linkChangeStream;

  @override
  void initState() {
    try {
      // HANDLE APP LAUNCH LINK
      getInitialUri()
          .then((initialUri) => handleLink(initialUri))
          .catchError((err) => handleIncomingLinkError(err));

      // HANDLE RUNTIME LINKS
      linkChangeStream = getUriLinksStream()
          .listen((uri) => handleLink(uri), onError: handleIncomingLinkError);
    } catch (err) {
      showAlert(
          title: Lang.of(context).get("Error"),
          text: Lang.of(context)
              .get("The link you followed appears to be invalid"),
          context: context);
    }

    // APP EVENT LISTENER
    WidgetsBinding.instance.addObserver(this);

    // DETERMINE INITIAL TAB
    final currentAccount =
        globalAppState.currentAccount; // It is expected to be non-null

    // No organizations => identity
    if (!currentAccount.entities.hasValue ||
        currentAccount.entities.value.length == 0) {
      selectedTab = 2;
    } else {
      // internally, this will only refresh outdated individual elements
      currentAccount.refresh(); // detached from async
    }

    super.initState();
  }

  handleLink(Uri givenUri) {
    if (givenUri == null) return;

    handleIncomingLink(givenUri, homePageScaffoldKey.currentContext)
        .catchError(handleIncomingLinkError);
  }

  handleIncomingLinkError(err) {
    print(err);
    showAlert(
        title: Lang.of(homePageScaffoldKey.currentContext).get("Error"),
        text: Lang.of(homePageScaffoldKey.currentContext)
            .get("There was a problem handling the link"),
        context: homePageScaffoldKey.currentContext);
  }

  /////////////////////////////////////////////////////////////////////////////
  // GLOBAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  Future<bool> handleWillPop() async {
    if (!Navigator.canPop(context)) {
      // dispose any resource in use
    }
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.inactive:
        if (!kReleaseMode) print("Inactive");
        break;
      case AppLifecycleState.paused:
        if (!kReleaseMode) print("Paused");
        break;
      case AppLifecycleState.resumed:
        if (!kReleaseMode) print("Resumed");
        connectGateways();
        break;
      case AppLifecycleState.suspending:
        if (!kReleaseMode) print("Suspending");
        break;
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // CLEANUP
  /////////////////////////////////////////////////////////////////////////////

  @override
  void dispose() {
    // RUNTIME LINK HANDLING
    if (linkChangeStream != null) linkChangeStream.cancel();

    // APP EVENT LISTENER
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  /////////////////////////////////////////////////////////////////////////////
  // MAIN
  /////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(context) {
    // We use Consumer() since the appState might change and we may need to redraw
    return Consumer<AppStateModel>(
      builder: (BuildContext context, AppStateModel appState, _) {
        return WillPopScope(
            onWillPop: handleWillPop,
            child: Scaffold(
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              floatingActionButtonAnimator:
                  FloatingActionButtonAnimator.scaling,
              floatingActionButton: selectedTab == 1
                  ? FloatingActionButton(
                      onPressed: () => onScanQrCode(context),
                      backgroundColor: colorDescription,
                      child: Icon(
                        FeatherIcons.plus,
                      ),
                      elevation: 5.0)
                  : null,
              appBar: TopNavigation(
                title: getTabName(selectedTab),
                showBackButton: false,
              ),
              key: homePageScaffoldKey,
              body: buildBody(context, appState),
              bottomNavigationBar: BottomNavigation(
                onTabSelect: (index) => onTabSelect(index),
                selectedTab: selectedTab,
              ),
            ));
      },
    );
  }

  buildBody(BuildContext ctx, AppStateModel appState) {
    Widget body;

    // RENDER THE CURRENT TAB BODY
    switch (selectedTab) {
      // VOTES FEED
      case 0:
        body = Consumer<FeedPoolModel>(
          builder: (BuildContext ctx, FeedPoolModel feeds, _) =>
              Consumer<ProcessPoolModel>(
            builder: (BuildContext ctx, ProcessPoolModel processes, _) =>
                HomeTab(),
          ),
        );
        break;
      // SUBSCRIBED ENTITIES
      case 1:
        body = Consumer<EntityPoolModel>(
          builder: (BuildContext ctx, EntityPoolModel processes, _) =>
              EntitiesTab(),
        );
        break;
      // IDENTITY INFO
      case 2:
        body = Consumer<AccountPoolModel>(
          builder: (BuildContext ctx, AccountPoolModel accounts, _) =>
              IdentityTab(),
        );
        break;
      default:
        body = Container(
          child: Center(
            child: Text("Vocdoni"),
          ),
        );
    }
    return body;
  }

  onTabSelect(int idx) {
    setState(() {
      selectedTab = idx;
    });
  }

  onScanQrCode(BuildContext context) async {
    String string = await new QRCodeReader()
        .setAutoFocusIntervalInMs(400) // default 5000
        .setForceAutoFocus(true) // default false
        .setTorchEnabled(true) // default false
        .setHandlePermissions(true) // default true
        .setExecuteAfterPermissionGranted(true) // default true
        .scan();

    final link = Uri.tryParse(string);
    if (link is Uri) handleIncomingLink(link, context);
    // TODO: else show error
  }

  String getTabName(int idx) {
    if (idx == 0)
      return "Home";
    else if (idx == 1)
      return "Your entities";
    else if (idx == 2)
      return "Your identity";
    else
      return "";
  }
}
