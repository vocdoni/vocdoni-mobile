import "package:flutter/material.dart";
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';


class DevUiElements extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "Post",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(text: "Simple item"),
            ListItem(text: "Item with icon", icon:FeatherIcons.anchor )
          ],
        ));
  }
}