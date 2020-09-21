import "package:flutter/material.dart";
import 'package:vocdoni/lib/globals.dart';
// import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
// import 'package:vocdoni/widgets/alerts.dart';
// import 'package:vocdoni/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:vocdoni/lib/i18n.dart';

class SignModalArguments {
  final String payload;
  final Uri returnUri;
  SignModalArguments({this.payload, this.returnUri});
}

class SignModal extends StatelessWidget {
  @override
  Widget build(context) {
    final SignModalArguments args = ModalRoute.of(context).settings.arguments;
    if (args == null || !(args is SignModalArguments))
      return buildEmptyData(context);
    else if (Globals.appState.currentAccount == null ||
        !Globals.appState.currentAccount.identity.hasValue)
      return buildEmptyAccount(context);

    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: getText(context, "main.sign"),
      ),
      body: Center(
        child: Column(children: <Widget>[
          Text(getText(context, "main.doYouWantToSign") + " " + args.payload),
          SizedBox(
            height: 20,
          ),
          Text(getText(context, "main.to") + " " + args.returnUri.toString()),
          SizedBox(
            height: 20,
          ),
          Text(getText(context, "main.using") +
              " " +
              Globals.appState.currentAccount.identity.value.alias +
              "?")
        ]),
      ),
    );
  }

  buildEmptyData(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: getText(context, "main.sign"),
      ),
      body: Center(
        child: Text(getText(context, "main.noData")),
      ),
    );
  }

  buildEmptyAccount(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: getText(context, "main.sign"),
      ),
      body: Center(
        child: Text(getText(context, "main.noData")),
      ),
    );
  }
}
