import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/toast.dart';
import '../lang/index.dart';
import 'identity-details.dart';

class IdentityWelcome extends StatefulWidget {
  @override
  _IdentityWelcome createState() => _IdentityWelcome();
}

class _IdentityWelcome extends State {
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
          child:generating
            ? Text("Generating sovereign identity...", style: TextStyle(fontSize: 18))
            : buildWelcome(context),
        ),
      ),
    ));
  }

  buildWelcome(BuildContext context){
    return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                  child: Text("Welcome!",
                      style: new TextStyle(
                          fontSize: 30, color: Color(0xff888888)))),
              SizedBox(height: 100),
              Center(
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(hintText: "What's your name?"),
                  onSubmitted: (alias) => {createIdentity(context, alias)},
                ),
              ),
            ],
          );
  }

  createIdentity(BuildContext context, String alias) async {
    try {
      
      setState(() {
        generating = true;
      });

      final mnemonic = await generateMnemonic();
      final address = await mnemonicToAddress(mnemonic);

      identitiesBloc.create(
          mnemonic: mnemonic, publicKey: "", address: address, alias: alias);

      int currentIndex = identitiesBloc.current.length;
      appStateBloc.selectIdentity(currentIndex);

      done(context);

    } catch (err) {
      String text = Lang.of(context)
          .get("An error occurred while generating the identity");

      showErrorMessage(text, context);
    }
  }

  done(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return IdentityDetails();
    }));
  }
}
