import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import '../lang/index.dart';

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

    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: Lang.of(context).get("Sign"),
      ),
      body: Center(
        child: Column(children: <Widget>[
          Text("Do you want to sign: " + args.payload),
          SizedBox(
            height: 20,
          ),
          Text("To: " + args.returnUri.toString()),
          SizedBox(
            height: 20,
          ),
          Text("Using: " +
              identitiesBloc
                  .value[appStateBloc.value.selectedIdentity].alias +
              "?")
        ]),
      ),
    );
  }

  buildEmptyData(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        showBackButton: true,
        title: Lang.of(context).get("Sign"),
      ),
      body: Center(
        child: Text("(No data)"),
      ),
    );
  }
}
