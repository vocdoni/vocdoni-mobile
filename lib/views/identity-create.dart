import "package:flutter/material.dart";
// import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
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
    return Scaffold(
        body: Center(
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
    ));
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
            onSubmitted: (alias) => onCreateIdentity(context, alias),
          ),
        ),
      ],
    );
  }

  onCreateIdentity(BuildContext context, String alias) async {
    try {
      setState(() {
        generating = true;
      });

      final mnemonic = await generateMnemonic();
      final publicKey = await mnemonicToPublicKey(mnemonic);
      final address = await mnemonicToAddress(mnemonic);

      await identitiesBloc.create(
          mnemonic: mnemonic,
          publicKey: publicKey,
          address: address,
          alias: alias);

      int currentIndex = identitiesBloc.current.length - 1;
      appStateBloc.selectIdentity(currentIndex);

      showHomePage(context);
    } catch (err) {
      String text = Lang.of(context)
          .get("An error occurred while generating the identity");

      showErrorMessage(text, context: context);
    }
  }

  showHomePage(BuildContext ctx) {
    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }
}
