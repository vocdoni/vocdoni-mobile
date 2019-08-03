import "package:flutter/material.dart";
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';


class DevUiElements extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "Post",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(text: "SimpleItem"),
            ListItem(text: "Item with icon")
          ],
        ));
  }
}