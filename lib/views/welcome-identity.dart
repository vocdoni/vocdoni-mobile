import "package:flutter/material.dart";
import '../lang/index.dart';

class WelcomeIdentityScreen extends StatelessWidget {
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
            InkWell(
                child: Text("CREATE AN IDENTITY"),
                onTap: () => createIdentity(context)),
            Spacer(),
            InkWell(
                child: Text("RECOVER AN IDENTITY"),
                onTap: () => recoverIdentity(context)),
            Spacer(),
          ],
        ),
      ),
    );
  }

  createIdentity(BuildContext context) {
    Navigator.pushNamed(context, "/welcome/identity/create");
  }

  recoverIdentity(BuildContext context) {
    Navigator.pushNamed(context, "/welcome/identity/recover");
  }
}
