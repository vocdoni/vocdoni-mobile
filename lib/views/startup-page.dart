import 'package:dvote/util/dev.dart';
import 'package:dvote_common/widgets/loading-spinner.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/views/identity-create-page.dart';
// import 'package:vocdoni/lib/extensions.dart';
import '../lib/singletons.dart';
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
    globalAnalytics.init();

    if (!mounted) return Future.value();
    setState(() {
      loading = true;
      error = null;
    });

    // READ PERSISTED DATA (protobuf)
    final persistenceReadPromises = <Future>[
      globalBootnodesPersistence.read(),
      globalIdentitiesPersistence.readAll(),
      globalEntitiesPersistence.readAll(),
      globalProcessesPersistence.readAll(),
      globalFeedPersistence.readAll(),
    ];

    return Future.wait(persistenceReadPromises)
        // POPULATE THE MODEL POOLS (Read into memory)
        .then((_) => Future.wait([
              // NOTE: Read's should be done first on the models that
              // don't depend on others to be restored
              globalProcessPool.readFromStorage(),
              globalFeedPool.readFromStorage(),
              globalAppState.readFromStorage(),
            ]))
        .then((_) => globalEntityPool.readFromStorage())
        .then((_) => globalAccountPool.readFromStorage())
        // FETCH REMOTE GATEWAYS, BLOCK HEIGHT, ETC
        .then((dvoteGw) {
      // Try to fetch bootnodes from the well-known URI

      return AppNetworking.init(forceReload: true).then((_) {
        if (!AppNetworking.isReady)
          throw Exception("No DVote Gateway is available");
      }).catchError((err) {
        devPrint("[App] Network initialization failed: $err");
        devPrint("[App] Trying to use the local gateway cache");

        // Retry with the existing cached gateways
        return AppNetworking.useFromGatewayInfo(
            globalAppState.bootnodeInfo.value);
      });
    }).then((_) {
      // DETERMINE THE NEXT SCREEN AND GO THERE
      if (globalAccountPool.hasValue && globalAccountPool.value.length > 0) {
        // Replace all routes with /identity/create on top
        Navigator.pushNamedAndRemoveUntil(
            context, "/identity/select", (Route _) => false);
      } else {
        // Create the first identity or allow to restore another one
        final route = MaterialPageRoute(
          builder: (context) =>
              IdentityCreatePage(showRestoreIdentityAction: true),
        );
        Navigator.pushAndRemoveUntil(context, route, (Route _) => false);
      }

      // Detached update of the cached bootnodes
      globalAppState.refresh(force: true).catchError(
          (err) => devPrint("[App] Detached bootnode update failed: $err"));
    }).catchError((err) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = getText(context, "main.couldNotConnectToTheNetwork");
      });

      // RETRY ITSELF
      Future.delayed(Duration(seconds: 10)).then((_) => initApplication());
    });
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
