import "package:flutter/material.dart";
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/util/dev/populate.dart';

class DevMenu extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "Post",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(
                mainText: "Add fake organizations",
                onTap: () async {
                  await populateSampleData();
                }),
            ListItem(
              mainText: "ListItem variations (UI)",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/ui-listItem");
              },
            ),
            ListItem(
              mainText: "Cards variations (UI)",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/ui-card");
              },
            ),
          ],
        ));
  }
}
