// import 'dart:io';
import 'dart:async';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/app-links.dart';

import 'package:vocdoni/views/feed-tab.dart';
import 'package:vocdoni/views/entities-tab.dart';
import 'package:vocdoni/views/identity-tab.dart';

import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/lang/index.dart';
// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

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
    // No organizations => identity
    if (identitiesBloc.current == null || identitiesBloc.current == null) {
      selectedTab = 2;
    } else if (appStateBloc != null &&
        appStateBloc.current != null &&
        identitiesBloc.current[appStateBloc.current.selectedIdentity].peers
                .entities !=
            null &&
        identitiesBloc.current[appStateBloc.current.selectedIdentity].peers
                .entities.length ==
            0) {
      selectedTab = 2;
    }

    super.initState();
  }

  handleLink(Uri givenUri) {
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
    switch (state) {
      case AppLifecycleState.inactive:
        print("Inactive");
        break;
      case AppLifecycleState.paused:
        print("Paused");
        break;
      case AppLifecycleState.resumed:
        print("Resumed");
        break;
      case AppLifecycleState.suspending:
        print("Suspending");
        break;
    }
    super.didChangeAppLifecycleState(state);
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
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                return WillPopScope(
                    onWillPop: handleWillPop,
                    child: Scaffold(
                      appBar: TopNavigation(
                        title: getTabName(selectedTab),
                        showBackButton: false,
                      ),
                      key: homePageScaffoldKey,
                      body: buildBody(ctx, appState?.data, identities?.data),
                      bottomNavigationBar: BottomNavigation(
                        onTabSelect: (index) => onTabSelect(index),
                        selectedTab: selectedTab,
                      ),
                    ));
              });
        });
  }

  buildBody(BuildContext ctx, AppState appState, List<Identity> identities) {
    Widget body;

    // RENDER THE CURRENT TAB BODY
    switch (selectedTab) {
      // VOTES FEED
      case 0:
        body = StreamBuilder(
            stream: newsFeedsBloc.stream,
            builder: (BuildContext ctx, AsyncSnapshot<List<Feed>> newsFeeds) {
              return FeedTab(
                  appState: appState,
                  identities: identities,
                  newsFeeds: newsFeeds.data ?? <Feed>[]);
            });
        break;
      // SUBSCRIBED ENTITIES
      case 1:
        body = EntitiesTab(appState: appState, identities: identities);
        break;
      // IDENTITY INFO
      case 2:
        body = IdentityTab(appState: appState, identities: identities);
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

  getTabName(int idx) {
    if (idx == 0) return "Home";
    if (idx == 1) return "Your entities";
    if (idx == 2) return "Your identity";
  }
}
