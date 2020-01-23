import 'dart:async';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/views/home-tab.dart';
import 'package:vocdoni/views/entities-tab.dart';
import 'package:vocdoni/views/identity-tab.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:qrcode_reader/qrcode_reader.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int selectedTab = 0;
  bool scanning = false;

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
    devPrint(err);
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
        devPrint("Inactive");
        break;
      case AppLifecycleState.paused:
        devPrint("Paused");
        break;
      case AppLifecycleState.resumed:
        devPrint("Resumed");
        ensureConnectedGateways();
        break;
      case AppLifecycleState.suspending:
        devPrint("Suspending");
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
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButton: selectedTab == 1
              ? Builder(
                  // Toast context descending from Scaffold
                  builder: (context) => FloatingActionButton(
                      onPressed: () => onScanQrCode(context),
                      backgroundColor: colorDescription,
                      child: Icon(
                        FeatherIcons.plus,
                      ),
                      elevation: 5.0))
              : null,
          appBar: TopNavigation(
            title: getTabName(selectedTab),
            showBackButton: false,
          ),
          key: homePageScaffoldKey,
          body: buildBody(context),
          bottomNavigationBar: BottomNavigation(
            onTabSelect: (index) => onTabSelect(index),
            selectedTab: selectedTab,
          ),
        ));
  }

  buildBody(BuildContext ctx) {
    Widget body;

    // RENDER THE CURRENT TAB BODY
    switch (selectedTab) {
      // VOTES FEED
      case 0:
        body = HomeTab();
        break;
      // SUBSCRIBED ENTITIES
      case 1:
        body = EntitiesTab();
        break;
      // IDENTITY INFO
      case 2:
        body = IdentityTab();
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
    if (scanning) return;
    scanning = true;

    try {
      final result = await QRCodeReader()
          .setAutoFocusIntervalInMs(400) // default 5000
          .setForceAutoFocus(true) // default false
          .setTorchEnabled(true) // default false
          .setHandlePermissions(true) // default true
          .setExecuteAfterPermissionGranted(true) // default true
          .scan();

      if (!(result is String)) throw Exception();

      final link = Uri.tryParse(result);
      if (!(link is Uri) || !link.hasScheme || link.hasEmptyPath)
        throw Exception();

      await handleIncomingLink(link, context);
      scanning = false;
    } catch (err) {
      scanning = false;

      await Future.delayed(Duration(milliseconds: 10));

      showMessage(
          "The QR code does not contain a valid link or the details cannot be retrieved",
          context: context,
          purpose: Purpose.DANGER);
    }
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
