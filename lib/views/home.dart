import 'dart:async';
import 'package:dvote_common/widgets/flavor-banner.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/view-modals/qr-scan-modal.dart';
import 'package:vocdoni/views/home-tab.dart';
import 'package:vocdoni/views/entities-tab.dart';
import 'package:vocdoni/views/identity-tab.dart';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:dvote_common/widgets/bottomNavigation.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int selectedTab = 0;
  bool scanning = false;

  /// Store it on build, so that external events like deep link handling can display
  /// snackbars on it
  BuildContext scaffoldBodyContext;

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
      showAlert(getText(context, "The link you followed appears to be invalid"),
          title: getText(context, "Error"), context: context);
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

    handleIncomingLink(givenUri, scaffoldBodyContext ?? context)
        .catchError(handleIncomingLinkError);
  }

  handleIncomingLinkError(err) {
    devPrint(err);
    showAlert(
        getText(scaffoldBodyContext ?? context,
            "There was a problem handling the link"),
        title: getText(scaffoldBodyContext ?? context, "Error"),
        context: scaffoldBodyContext ?? context);
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
      case AppLifecycleState.detached:
        devPrint("Detached");
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
      child: FlavorBanner(
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButton: selectedTab == 1
              ? Builder(
                  // Toast context descending from Scaffold
                  builder: (floatingBtnContext) => FloatingActionButton(
                      onPressed: () => onScanQrCode(floatingBtnContext),
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
          body: Builder(builder: (ctx) {
            // Store the build context from the scaffold, so that deep links can show
            // snackbars on top of this scaffold
            scaffoldBodyContext = ctx;

            return buildBody(context);
          }),
          bottomNavigationBar: BottomNavigation(
            onTabSelect: (index) => onTabSelect(index),
            selectedTab: selectedTab,
          ),
        ),
      ),
    );
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

  onScanQrCode(BuildContext floatingBtnContext) async {
    if (scanning) return;
    scanning = true;

    try {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true, builder: (context) => QrScanModal()));

      if (!(result is String)) {
        scanning = false;
        return;
      }
      // await Future.delayed(Duration(milliseconds: 50));

      final link = Uri.tryParse(result);
      if (!(link is Uri) || !link.hasScheme || link.hasEmptyPath)
        throw Exception("Invalid URI");

      await handleIncomingLink(link, scaffoldBodyContext ?? context);
      scanning = false;
    } catch (err) {
      scanning = false;

      await Future.delayed(Duration(milliseconds: 10));

      showMessage(
          getText(context,
              "The QR code does not contain a valid link or the details cannot be retrieved"),
          context: scaffoldBodyContext,
          purpose: Purpose.DANGER);
    }
  }

  String getTabName(int idx) {
    if (idx == 0)
      return getText(context, "Home");
    else if (idx == 1)
      return getText(context, "Your entities");
    else if (idx == 2)
      return getText(context, "Your identity");
    else
      return "";
  }
}
