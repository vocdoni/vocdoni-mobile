import 'package:dvote_common/widgets/loading-spinner.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/startup.dart';
// import 'package:vocdoni/lib/extensions.dart';
import '../lib/globals.dart';
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
    Globals.analytics.init();

    if (!mounted) return Future.value();
    setState(() {
      loading = true;
      error = null;
    });

    return restorePersistence()
        .then((_) => restoreDataPools()) // Depends on restorePersistence()
        .then((_) => showNextScreen(context))
        .catchError((err) {
      print("Startup error: $err");
      if (!mounted) return;

      setState(() {
        loading = false;
        error = getText(context, "main.couldNotRefresh");
      });
    });
  }

  void showNextScreen(BuildContext context) {
    // Determine the next screen and go there
    String nextRoutePath;
    if (Globals.accountPool.hasValue && Globals.accountPool.value.length > 0) {
      Globals.appState.selectAccount(0);
      if (Globals.appState.currentAccount is! AccountModel)
        throw Exception("No account available");

      nextRoutePath = "/home";
    } else {
      nextRoutePath = "/identity/create";
    }

    // Replace all routes nextRoutePath on top
    Navigator.pushNamedAndRemoveUntil(
        context, nextRoutePath, (Route _) => false);
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
