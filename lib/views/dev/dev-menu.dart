import "package:flutter/material.dart";
import 'package:vocdoni/lib/app-links.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/dev/populate.dart';

class DevMenu extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: "Post",
      ),
      body: Builder(
          builder: (BuildContext context) => ListView(
                children: <Widget>[
                  ListItem(
                      mainText: "Add fake organizations",
                      onTap: () {
                        populateSampleData();
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
                    mainText: "Handle deeplink (Esqueixada)",
                    onTap: () {
                      String link =
                          'https://app.vocdoni.net/entities/#/0x8dfbc9c552338427b13ae755758bb5fd7df4fce0f98ceff56c791e5b74fcffba';
                      handleIncomingLink(Uri.parse(link), context);
                    },
                  ),
                  ListItem(
                    mainText: "Handle deeplink (VocdoniTest)",
                    onTap: () {
                      String link =
                          'https://app.vocdoni.net/entities/#/0x33e9ee1a35cc74dee64e13b46db4f52d61bb450a71cfcb810a3175d1f308f658';
                      handleIncomingLink(Uri.parse(link), context);
                    },
                  ),
                  ListItem(
                    mainText: "Handle deeplink (A new world)",
                    onTap: () {
                      String link =
                          'https://app.vocdoni.net/entities/#/0xf6a97d2ec8bb9fabde28b9e377edbd31e92bef3b44040f0752e28896f4baed90';
                      handleIncomingLink(Uri.parse(link), context);
                    },
                  ),
                  ListItem(
                    mainText: "Analytics",
                    onTap: () {
                      Navigator.pushNamed(ctx, "/dev/analytics-tests");
                    },
                  ),
                  ListItem(
                    mainText: "Pager test",
                    onTap: () {
                      Navigator.pushNamed(ctx, "/dev/pager");
                    },
                  ),
                ],
              )),
    );
  }
}
