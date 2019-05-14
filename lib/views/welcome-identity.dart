import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';

class WelcomeIdentityScreen extends StatelessWidget {
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
            Text(Lang.of(context).get("Welcome")),
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: FlatButton(
                  color: mainBackgroundColor,
                  textColor: mainTextColor,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                  onPressed: () {
                    createIdentity(context);
                  },
                  child: Text(Lang.of(context).get("Create an identity")),
                ),
              ),
            ),
            SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: FlatButton(
                  color: mainBackgroundColor,
                  textColor: mainTextColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  onPressed: () {
                    recoverIdentity(context);
                  },
                  child: Text(Lang.of(context).get("Import an identity")),
                ),
              ),
            ),
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
