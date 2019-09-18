import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';

class PollPackaging extends StatefulWidget {
  @override
  _PollPackagingState createState() => _PollPackagingState();
}

class _PollPackagingState extends State<PollPackaging> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Section(text: "Preparing vote"),
          ListItem(
            mainText: "Signed",
            rightIcon: FeatherIcons.check,
            rightTextPurpose: Purpose.GOOD,
          ),
          ListItem(mainText: "Generating proof"),
          ListItem(mainText: "Encrypting"),
          ListItem(mainText: "Sending"),
          ListItem(mainText: "Waiting for confirmation"),
        ],
      ),
    );
  }
}
