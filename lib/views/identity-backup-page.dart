import 'package:dvote_common/widgets/topNavigation.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/extensions.dart';

class IdentityBackupArguments {
  final String alias;
  final String mnemonic;

  IdentityBackupArguments(this.alias, this.mnemonic);
}

class IdentityBackupPage extends StatefulWidget {
  @override
  _IdentityBackupPageState createState() => _IdentityBackupPageState();
}

class _IdentityBackupPageState extends State<IdentityBackupPage> {
  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("IdentityBackupPage");
  }

  Widget renderOkButton() {
    return FlatButton(
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
    ).withPadding(16).withTopPadding(8);
  }

  @override
  Widget build(context) {
    final IdentityBackupArguments args =
        ModalRoute.of(context).settings.arguments;

    final List<Widget> items = [
      Text("Please, take a sheet of paper, write down the following words in order and keep them in a safe place.")
          .withPadding(16)
    ];
    final words = args.mnemonic.split(" ");
    final halfLen = words.length >> 1;

    for (int i = 0; i < halfLen; i++) {
      items.add(Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              child: MnemonicWord(word: words[i], idx: i),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              child: MnemonicWord(word: words[i + halfLen], idx: i + halfLen),
            ),
          ),
        ],
      ).withVPadding(8).withHPadding(16));
    }
    items.add(renderOkButton());

    return Scaffold(
      appBar: TopNavigation(
        title: "Identity Backup",
      ),
      body: ListView(children: items),
    );
  }
}

class MnemonicWord extends StatelessWidget {
  final int idx;
  final String word;

  MnemonicWord({this.idx, this.word});

  @override
  Widget build(context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 20,
          child: Text(
            (idx + 1).toString(),
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            child: Text(word,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold))
                .withVPadding(8)
                .withHPadding(16),
            decoration: BoxDecoration(
                color: colorChip,
                borderRadius: BorderRadius.all(Radius.circular(16.0))),
          ).withHPadding(8),
        ),
      ],
    );
  }
}
