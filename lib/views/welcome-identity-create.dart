import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../util/singletons.dart';
import '../lang/index.dart';
import "../widgets/snackbars.dart";

class WelcomeIdentityCreateScreen extends StatefulWidget {
  @override
  _WelcomeIdentityCreateScreenState createState() =>
      _WelcomeIdentityCreateScreenState();
}

class _WelcomeIdentityCreateScreenState
    extends State<WelcomeIdentityCreateScreen> {
  String generatedMnemonic;

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
            Text(generatedMnemonic != null
                ? generatedMnemonic
                : Lang.of(context)
                    .get("Tap to create your self-sovereign identity")),
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Padding(
                  padding: EdgeInsets.only(left: 5, right: 5, top: 5),
                  child: Builder(builder: (BuildContext context) {
                    return FlatButton(
                      color: mainBackgroundColor,
                      textColor: mainTextColor,
                      padding: EdgeInsets.all(16),
                      onPressed: () {
                        if (generatedMnemonic != null)
                          done(context);
                        else
                          createIdentity(context);
                      },
                      child: Text(generatedMnemonic != null
                          ? Lang.of(context).get("Continue")
                          : Lang.of(context).get("Create identity")),
                    );
                  })),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  createIdentity(BuildContext context) async {
    try {
      final mnemonic = await webRuntime.call("generateMnemonic()");
      showMessage(mnemonic, context);

      setState(() {
        generatedMnemonic = mnemonic;
      });

      // TODO: STORE

    } catch (err) {
      String text = Lang.of(context)
          .get("An error occurred while generating the identity");

      showErrorMessage(text, context);
    }
  }

  done(BuildContext context) {
    Navigator.pushReplacementNamed(context, "/home");
  }
}
