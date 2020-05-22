import "package:flutter/material.dart";
import 'package:vocdoni/lib/singletons.dart';
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
    else if (globalAppState.currentAccount == null ||
        !globalAppState.currentAccount.identity.hasValue)
      return buildEmptyAccount(context);

    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: getText(context, "Sign"),
      ),
      body: Center(
        child: Column(children: <Widget>[
          Text(getText(context, "Do you want to sign:") + " " + args.payload),
          SizedBox(
            height: 20,
          ),
          Text(getText(context, "To:") + " " + args.returnUri.toString()),
          SizedBox(
            height: 20,
          ),
          Text(getText(context, "Using:") +
              " " +
              globalAppState.currentAccount.identity.value.alias +
              "?")
        ]),
      ),
    );
  }

  buildEmptyData(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: getText(context, "Sign"),
      ),
      body: Center(
        child: Text(getText(context, "(No data)")),
      ),
    );
  }

  buildEmptyAccount(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: getText(context, "Sign"),
      ),
      body: Center(
        child: Text(getText(context, "(No data)")),
      ),
    );
  }
}
