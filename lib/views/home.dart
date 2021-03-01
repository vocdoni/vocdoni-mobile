import 'dart:async';

import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:dvote_common/widgets/bottomNavigation.dart';
import 'package:dvote_common/widgets/flavor-banner.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/notifications.dart';
import 'package:vocdoni/lib/startup.dart';
import 'package:vocdoni/view-modals/qr-scan-modal.dart';
import 'package:vocdoni/views/home-content-tab.dart';
import 'package:vocdoni/views/home-entities-tab.dart';
import 'package:vocdoni/views/home-identity-tab.dart';
// import 'package:vocdoni/lib/extensions.dart';

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
      if (AppNetworking.dvoteIsReady()) {
        // Only refresh if networking is available
        Globals.appState.currentAccount.refresh();
      } else {
        startNetworking()
            .then((_) => Globals.appState.currentAccount.refresh());
      }
      Future.delayed(Duration(seconds: 1)).then((_) {
        if (Globals.appState.bootnodeInfo.hasError)
          showMessage(
              getText(context,
                  "error.unableToConnectToGatewaysTheBootnodeUrlOrBlockchainNetworkIdMayBeInvalid"),
              context: scaffoldBodyContext ?? context,
              purpose: Purpose.DANGER);
      });

      // HANDLE APP LAUNCH LINK
      getInitialUri()
          .then((uri) => handleLink(uri))
          .catchError((err) => buildHandleIncomingLinkError()(err));

      // HANDLE RUNTIME LINKS
      linkChangeStream = getUriLinksStream().listen((uri) => handleLink(uri),
          onError: buildHandleIncomingLinkError());

      // Display the screen for a notification (if one is pending)
      Future.delayed(Duration(seconds: 1))
          .then((_) => Notifications.handlePendingNotification());
    } catch (err) {
      showAlert(getText(context, "main.theLinkYouFollowedAppearsToBeInvalid"),
          title: getText(context, "main.error"), context: context);
    }

    // APP EVENT LISTENER
    WidgetsBinding.instance.addObserver(this);

    // DETERMINE INITIAL TAB
    final currentAccount =
        Globals.appState.currentAccount; // It is expected to be non-null

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
        logger.log("Inactive");
        break;
      case AppLifecycleState.paused:
        logger.log("Paused");
        break;
      case AppLifecycleState.resumed:
        logger.log("Resumed");
        if (!AppNetworking.isReady()) AppNetworking.init(forceReload: true);
        break;
      case AppLifecycleState.detached:
        logger.log("Detached");
        break;
    }
  }

  handleLink(Uri uri) {
    genericHandleLink(uri, scaffoldBodyContext ?? context);
  }

  buildHandleIncomingLinkError() {
    return genericHandleIncomingLinkError(scaffoldBodyContext ?? context);
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
        mode: AppConfig.APP_MODE,
        child: Scaffold(
          appBar: TopNavigation(
            title: getTabName(selectedTab),
            showBackButton: false,
          ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          // floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButton: selectedTab == 1 ? buildFab(context) : null,
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

  buildFab(BuildContext context) {
    // Force the toast context to descend from Scaffold and not from the widget
    return Builder(builder: (floatingBtnContext) {
      // final entitiesCount =
      //     globalAppState.currentAccount?.entities?.value?.length ?? 0;

      // if (entitiesCount == 0) {
      //   return FloatingActionButton.extended(
      //       onPressed: () => onScanQrCode(floatingBtnContext),
      //       backgroundColor: colorDescription,
      //       label: Row(children: [
      //         Text(getText(context, "action.scanQrCode")),
      //         Icon(Icons.camera_alt).withLeftPadding(15)
      //       ]));
      // }

      return FloatingActionButton(
        onPressed: () => onScanQrCodeOrInput(floatingBtnContext),
        backgroundColor: colorDescription,
        child: Icon(FeatherIcons.plus),
        elevation: 5.0,
        tooltip: getText(context, "tooltip.scanaQrCode"),
      );
    });
  }

  buildBody(BuildContext ctx) {
    Widget body;

    // RENDER THE CURRENT TAB BODY
    switch (selectedTab) {
      // VOTES+FEED
      case 0:
        body = HomeContentTab();
        break;
      // SUBSCRIBED ENTITIES
      case 1:
        body = HomeEntitiesTab();
        break;
      // IDENTITY INFO
      case 2:
        body = HomeIdentityTab();
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

  onScanQrCodeOrInput(BuildContext floatingBtnContext) async {
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
              "error.theCodeDoesNotContainAValidLinkOrTheDetailsCannotBeRetrieved"),
          context: scaffoldBodyContext,
          purpose: Purpose.DANGER);
    }
  }

  String getTabName(int idx) {
    if (idx == 0)
      return getText(context, "main.home");
    else if (idx == 1)
      return getText(context, "main.yourEntities");
    else if (idx == 2)
      return getText(context, "main.yourIdentity");
    else
      return "";
  }
}
