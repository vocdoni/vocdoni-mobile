import "package:flutter/material.dart";

class WelcomeIdentityCreateScreen extends StatelessWidget {
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
