import 'package:flutter/material.dart';
import '../util/singletons.dart';

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
    analytics.init();

    // RESTORE PERSISTED DATA
    return appStateBloc
        .init()
        .then((_) => entitiesBloc.init())
        .then((_) => identitiesBloc.init())
        .then((_) => newsFeedsBloc.init())
        .then((_) => processesBloc.init())
        // FETCH REMOTE GATEWAYS, BLOCK HEIGHT, ETC
        .then((_) => appStateBloc.fetchRemoteState())
        // DETERMINE THE NEXT SCREEN AND GO THERE
        .then((_) {
      if (identitiesBloc.value.length > 0 ?? false) {
        // Replace all routes with /identity/select on top
        Navigator.pushNamedAndRemoveUntil(
            context, "/identity/select", (Route _) => false);
      } else {
        // Replace all routes with /identity/create on top
        Navigator.pushNamedAndRemoveUntil(
            context, "/identity/create", (Route _) => false);
      }
    }).catchError((err) {
      setState(() {
        loading = false;
        // if (err is String) error = err;
        // else
        error = "Could not load the status of the app";
      });

      // RETRY
      Future.delayed(Duration(seconds: 5))
          .then((_) => initApplication())
          .catchError((_) {});
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
