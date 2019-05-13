import "package:flutter/material.dart";
import '../lang/index.dart';

class WelcomeIdentityRecoverScreen extends StatelessWidget {
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
            InkWell(
                child: Text("RECOVER IDENTITY"),
                onTap: () => recoverIdentity(context)),
            Spacer(),
          ],
        ),
      ),
    );
  }

  recoverIdentity(BuildContext context) {
    Navigator.pushReplacementNamed(context, "/home");
  }
}
