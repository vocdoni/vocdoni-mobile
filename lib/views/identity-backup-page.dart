import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';

class IdentityBackupArguments {
  final String alias;
  final String mnemonic;

  IdentityBackupArguments(this.alias, this.mnemonic);
}

class MnemonicWord extends StatelessWidget {
  final int idx;
  final String word;

  MnemonicWord({this.idx, this.word});

  @override
  Widget build(context) {
    return Row(children: <Widget>[
      Text(idx.toString()),
      SizedBox(
        width: 10,
      ),
      Container(
        alignment: Alignment(0, 0),
        padding: EdgeInsets.all(paddingChip),
        constraints: BoxConstraints(maxWidth: 150, maxHeight: 40),
        decoration: new BoxDecoration(
            color: colorChip,
            borderRadius: new BorderRadius.all(const Radius.circular(5.0))),
        child: Text(word, style: TextStyle(fontSize: 14)),
      )
    ]);
  }
}

class Mnemonic2Columns extends StatelessWidget {
  final List<String> mnemonic;

  Mnemonic2Columns({this.mnemonic});

  @override
  Widget build(context) {
    int half = (mnemonic.length / 2).ceil();
    List<String> l1 = mnemonic.sublist(0, half);
    List<String> l2 = mnemonic.sublist(half, mnemonic.length);
    int i = 1;

    return Container(
        constraints: BoxConstraints(maxHeight: 500, maxWidth: 400),
        color: Color(0x00ff0000),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: l1
                  .map((word) => MnemonicWord(
                        idx: i++,
                        word: word,
                      ))
                  .toList()),
          Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: l2
                  .map((word) => MnemonicWord(
                        idx: i++,
                        word: word,
                      ))
                  .toList())
        ]));
  }
}

class IdentityBackupPage extends StatefulWidget {
  @override
  _IdentityBackupPageState createState() => _IdentityBackupPageState();
}

class _IdentityBackupPageState extends State<IdentityBackupPage> {
  @override
  void initState() {
    super.initState();
    analytics.trackPage(pageId: "IdentityBackupPage");
  }

  @override
  Widget build(context) {
    final IdentityBackupArguments args =
        ModalRoute.of(context).settings.arguments;
    List<String> words = args.mnemonic.split(" ");

    return Scaffold(
        body: Center(
      child: Align(
          alignment: Alignment(0, 0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Mnemonic2Columns(mnemonic: words),
                FlatButton(
                  color: colorBlue,
                  textColor: Colors.white,
                  disabledColor: Colors.grey,
                  disabledTextColor: Colors.black,
                  padding: EdgeInsets.all(paddingButton),
                  splashColor: Colors.blueAccent,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "I wrote them down",
                    style: TextStyle(fontSize: 20.0),
                  ),
                )
              ])),
    ));
  }
}
