import 'package:flutter/material.dart';
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

    // READ PERSISTED DATA
    return Future.wait([
      globalBootnodesPersistence.read(),
      globalIdentitiesPersistence.readAll(),
      globalEntitiesPersistence.readAll(),
      globalProcessesPersistence.readAll(),
      globalFeedPersistence.readAll(),
    ]).then((_) {
      // POPULATE THE MODEL POOLS
      return Future.wait([
        globalAppState.readFromStorage(),
        globalAccountPool.readFromStorage(),
        globalEntityPool.readFromStorage(),
        globalFeedPool.readFromStorage(),
        globalProcessPool.readFromStorage()
      ]);
    }).then((_) {
      // FETCH REMOTE GATEWAYS, BLOCK HEIGHT, ETC
      return Future.wait([
        globalAppState.refresh(),
      ]);
    }).then((_) {
      // DETERMINE THE NEXT SCREEN AND GO THERE
      String nextRoutePath;
      if (globalAccountPool.hasValue && globalAccountPool.value.length > 0) {
        nextRoutePath = "/identity/select";
      } else {
        nextRoutePath = "/identity/create";
      }

      // Replace all routes with /identity/select on top
      Navigator.pushNamedAndRemoveUntil(
          context, nextRoutePath, (Route _) => false);
    }).catchError((err) {
      setState(() {
        loading = false;
        error = "Could not load the status of the app";
      });

      // RETRY ITSELF
      Future.delayed(Duration(seconds: 5)).then((_) => initApplication());
    });
  }

  Widget buildError(BuildContext context) {
    return Center(
        child: Text(
      "Error:\n" + error,
      style: new TextStyle(fontSize: 26, color: Color(0xff888888)),
      textAlign: TextAlign.center,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Builder(builder: (BuildContext context) {
      return Center(
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
      );
    }));
  }
}
