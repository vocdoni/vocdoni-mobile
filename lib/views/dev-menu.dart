import "package:flutter/material.dart";
import 'package:vocdoni/util/app-links.dart';
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
            ListItem(
              mainText: "Avatar color generation (UI)",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/ui-avatar-colors");
              },
            ),
            ListItem(
              mainText: "Handle deeplink",
              onTap: () {
                String link =
                    'vocdoni://vocdoni.app/entity?entityId=0x8dfbc9c552338427b13ae755758bb5fd7df4fce0f98ceff56c791e5b74fcffba&entryPoints[]=https://gwdev1.vocdoni.net/web3&entryPoints[]=https://gwdev2.vocdoni.net/web3';
                    handleIncomingLink(Uri.parse(link), ctx);
              },
            ),
          ],
        ));
  }
}
