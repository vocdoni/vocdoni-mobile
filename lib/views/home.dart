import 'dart:async';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/app-links.dart';

import 'package:vocdoni/views/feed-tab.dart';
import 'package:vocdoni/views/organizations-tab.dart';
import 'package:vocdoni/views/identity-tab.dart';

import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  /////////////////////////////////////////////////////////////////////////////
  // DEEP LINKS / UNIVERSAL LINKS
  /////////////////////////////////////////////////////////////////////////////

  StreamSubscription<Uri> linkChangeStream;

  @override
  void initState() {
    try {
      // Handle the app launch link
      getInitialUri()
          .then((initialUri) => handleLink(initialUri))
          .catchError((err) => handleIncomingLinkError(err));

      // Listen to link changes
      linkChangeStream = getUriLinksStream()
          .listen((uri) => handleLink(uri), onError: handleIncomingLinkError);
    } catch (err) {
      showAlert(
          title: Lang.of(context).get("Error"),
          text: Lang.of(context)
              .get("The link you followed appears to be invalid"),
          context: context);
    }

    // Check if there are no organizations => show identity
    if (identitiesBloc.current == null || identitiesBloc.current == null) {
      selectedTab = 2;
    } else if (appStateBloc != null &&
        appStateBloc.current != null &&
        identitiesBloc
                .current[appStateBloc.current.selectedIdentity].organizations !=
            null &&
        identitiesBloc.current[appStateBloc.current.selectedIdentity]
                .organizations.length ==
            0) {
      selectedTab = 2;
    }

    super.initState();
  }

  handleLink(Uri givenUri) {
    handleIncomingLink(givenUri, homePageScaffoldKey.currentContext)
        .then((String result) => handleLinkSuccess(result))
        .catchError(handleIncomingLinkError);
  }

  handleLinkSuccess(String text) {
    if (text == null || !(text is String)) return;

    showSuccessMessage(text, global: true);
  }

  handleIncomingLinkError(err) {
    if (err == "Already subscribed") {
      return showMessage(
          Lang.of(context)
              .get("You are already subscribed to this organization"),
          global: true);
    }
    print(err);
    showAlert(
        title: Lang.of(homePageScaffoldKey.currentContext).get("Error"),
        text: Lang.of(homePageScaffoldKey.currentContext)
            .get("There was a problem handling the link provided"),
        context: homePageScaffoldKey.currentContext);
  }

  @override
  void dispose() {
    if (linkChangeStream != null) linkChangeStream.cancel();
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
                return Scaffold(
                  appBar: TopNavigation(
                    title: getTabName(selectedTab),
                  ),
                  backgroundColor: baseBackgroundColor,
                  key: homePageScaffoldKey,
                  body: buildBody(ctx, appState.data, identities.data),
                  bottomNavigationBar: BottomNavigation(
                    onTabSelect: (index) => onTabSelect(index),
                    selectedTab: selectedTab,
                  ),
                );
              });
        });
  }

  buildBody(BuildContext ctx, AppState appState, List<Identity> identities) {
    Widget body;

    // RENDER THE CURRENT TAB BODY
    switch (selectedTab) {
      // VOTES FEED
      case 0:
        body = FeedTab(appState: appState, identities: identities);
        break;
      // SUBSCRIBED ORGANIZATIONS
      case 1:
        body = OrganizationsTab(
          appState: appState,
          identities: identities,
        );
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
    if (idx == 1) return "Your organizations";
    if (idx == 2) return "Your identity";
  }
}
