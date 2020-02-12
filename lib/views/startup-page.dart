import 'package:flutter/material.dart';
import 'package:vocdoni/lib/net.dart';
import '../lib/singletons.dart';

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

    setState(() {
      loading = true;
      error = null;
    });

    // READ PERSISTED DATA (protobuf)
    return Future.wait([
      globalBootnodesPersistence.read(),
      globalIdentitiesPersistence.readAll(),
      globalEntitiesPersistence.readAll(),
      globalProcessesPersistence.readAll(),
      globalFeedPersistence.readAll(),
    ])
        .then((_) {
          // POPULATE THE MODEL POOLS (Read into memory)
          return Future.wait([
            // NOTE: Read's should be done first on the models that
            // don't depend on others to be restored
            globalProcessPool.readFromStorage(),
            globalFeedPool.readFromStorage(),
            globalAppState.readFromStorage(),
          ])
              .then((_) => globalEntityPool.readFromStorage())
              .then((_) => globalAccountPool.readFromStorage());
        })
        .then((_) {
          // FETCH REMOTE GATEWAYS, BLOCK HEIGHT, ETC
          return globalAppState.refresh(true);
        })
        .then(
          (_) => getDVoteGateway().then((dvoteGw) {
            if (dvoteGw == null)
              throw Exception("No DVote Gateway is available");
          }),
        )
        .then((_) {
          // DETERMINE THE NEXT SCREEN AND GO THERE
          String nextRoutePath;
          if (globalAccountPool.hasValue &&
              globalAccountPool.value.length > 0) {
            nextRoutePath = "/identity/select";
          } else {
            nextRoutePath = "/identity/create";
          }

          // Replace all routes with /identity/select on top
          Navigator.pushNamedAndRemoveUntil(
              context, nextRoutePath, (Route _) => false);
        })
        .catchError((err) {
          setState(() {
            loading = false;
            error = "Could not load the status of the app";
          });

          // RETRY ITSELF
          Future.delayed(Duration(seconds: 10)).then((_) => initApplication());
        });
  }

  Widget buildError(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Text(
          "Error:\n$error",
          style: new TextStyle(fontSize: 26, color: Color(0xff888888)),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.0),
        InkWell(
            onTap: () => initApplication(),
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Text(
                  "Tap to retry",
                  style: TextStyle(fontSize: 18, color: Colors.black45),
                  textAlign: TextAlign.center,
                )))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: Align(
            alignment: Alignment(0, -0.3),
            child: Container(
              constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
              color: Color(0x00ff0000),
              child: loading
                  ? Text("Please, wait...", style: TextStyle(fontSize: 18))
                  : buildError(context),
            ),
          ),
        ),
      ),
    );
  }
}
