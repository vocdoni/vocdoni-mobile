import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';

class AnalyticsTests extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "List item variants",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(
              mainText: "Track 1",
              onTap: analytics.track("Track1Tap"),
            ),
          ],
        ));
  }
}
