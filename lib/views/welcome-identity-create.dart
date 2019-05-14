import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';

class WelcomeIdentityCreateScreen extends StatelessWidget {
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
            Spacer(),
            InkWell(
                child: Text("CREATE IDENTITY"),
                onTap: () => createIdentity(context)),
            Spacer(),
          ],
        ),
      ),
    );
  }

  createIdentity(BuildContext context) {
    Navigator.pushReplacementNamed(context, "/home");
  }
}
