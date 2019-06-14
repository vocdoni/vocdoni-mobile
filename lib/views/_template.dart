import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';
import '../util/singletons.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vocdoni"),
        backgroundColor: mainBackgroundColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkWell(
                child: Text("Action trigger"),
                onTap: () => handleRuntimeCall()),
            Spacer(),
            InkWell(child: Text("Set Entity ++"), onTap: () => incIdent()),
            Spacer(),
            StreamBuilder(
                stream: appStateBloc.stream,
                builder:
                    (BuildContext context, AsyncSnapshot<AppState> snapshot) {
                  final state = snapshot?.data;
                  return Text("Entity Idx: ${state?.selectedIdentity ?? 0}");
                }),
            Spacer(),
          ],
        ),
      ),
    );
  }

  handleRuntimeCall() {
    print("Tap");
  }

  incIdent() {
    appStateBloc.selectIdentity(appStateBloc.current.selectedIdentity + 1);
  }
}
