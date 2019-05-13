import "package:flutter/material.dart";
import '../lang/index.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vocdoni"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            Text(Lang.of(context).welcome),
            Spacer(),
            Text("ONBOARDING PAGE"),
            Spacer(),
            InkWell(child: Text("CONTINUE (push)"), onTap: () => go(context)),
            Spacer(),
            InkWell(
                child: Text("SKIP TO HOME (replace)"),
                onTap: () => replace(context)),
            Spacer(),
          ],
        ),
      ),
    );
  }

  go(BuildContext context) {
    Navigator.pushNamed(context, "/welcome/identity");
  }

  replace(BuildContext context) {
    Navigator.pushReplacementNamed(context, "/home");
  }
}
