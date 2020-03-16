import "package:flutter/material.dart";
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';

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
              mainText: "Track page Page1",
              onTap: globalAnalytics.trackPage("Page1"),
            ),
          ],
        ));
  }
}
