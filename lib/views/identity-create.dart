import "package:flutter/material.dart";
import 'package:vocdoni/modals/create-pattern-modal.dart';
// import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/toast.dart';
import '../lang/index.dart';

class IdentityCreateScreen extends StatefulWidget {
  @override
  _IdentityCreateScreen createState() => _IdentityCreateScreen();
}

class _IdentityCreateScreen extends State {
  bool generating = false;

  @override
  Widget build(context) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(body: Builder(builder: (BuildContext context) {
          return Center(
            child: Align(
              alignment: Alignment(0, -0.3),
              child: Container(
                constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
                color: Color(0x00ff0000),
                child: generating
                    ? Text("Generating sovereign identity...",
                        style: TextStyle(fontSize: 18))
                    : buildWelcome(context),
              ),
            ),
          );
        })));
  }

  buildWelcome(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
            child: Text("Welcome!",
                style: new TextStyle(fontSize: 30, color: Color(0xff888888)))),
        SizedBox(height: 100),
        Center(
          child: TextField(
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(hintText: "What's your name?"),
              onSubmitted: (alias) => setPattern(context, alias)),
        ),
      ],
    );
  }

  setPattern(BuildContext context, String alias) async {
    String pattern = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => CreatePatternModal(
                  canGoBack: true,
                )));

    if (pattern == null) {
      showMessage("Pattern was cancelled", context: context);
    } else {
      showSuccessMessage("Pattern has been set!", context: context);
      onCreateIdentity(context, alias, pattern);
    }
  }

  encrypt(String key, String payload) async {
    //TODO: encrypt 
    return payload;
  }

  onCreateIdentity(BuildContext context, String alias, String encryptionKey) async {
    try {
      setState(() {
        generating = true;
      });

      final mnemonic = await generateMnemonic();
      final publicKey = await mnemonicToPublicKey(mnemonic);
      final address = await mnemonicToAddress(mnemonic);
      final encryptedMenmonic = await encrypt(encryptionKey, mnemonic);

     // debugPrint("encryptedMenmonic" + ' ' + encryptedMenmonic);

      await identitiesBloc.create(
          mnemonic: mnemonic,
          publicKey: publicKey,
          address: address,
          alias: alias);

      int currentIndex = identitiesBloc.current.length - 1;
      appStateBloc.selectIdentity(currentIndex);

      showHomePage(context);
    } catch (err) {
      setState(() {
        generating = false;
      });
      String text = Lang.of(context)
          .get("An error occurred while generating the identity");

      if (err == "The account already exists") {
        text = Lang.of(context).get("The account already exists");
      }
      showAlert(
          title: Lang.of(context).get("Error"), text: text, context: context);
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // GLOBAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  Future<bool> handleWillPop() async {
    if (!Navigator.canPop(context)) {
      // dispose any resource in use
    }
    return true;
  }

  /////////////////////////////////////////////////////////////////////////////
  // LOCAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  showHomePage(BuildContext ctx) {
    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }
}
