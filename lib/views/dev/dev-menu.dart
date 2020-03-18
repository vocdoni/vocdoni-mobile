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
                          'vocdoni://vocdoni.app/entity?entityId=0x8dfbc9c552338427b13ae755758bb5fd7df4fce0f98ceff56c791e5b74fcffba&entryPoints[]=https://gwdev1.vocdoni.net/web3&entryPoints[]=https://gwdev2.vocdoni.net/web3';
                      handleIncomingLink(Uri.parse(link), ctx);
                    },
                  ),
                  ListItem(
                    mainText: "Handle deeplink (VocdoniTest)",
                    onTap: () {
                      String link =
                          'vocdoni://vocdoni.app/entity?entityId=0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85&entryPoints[]=https://gwdev1.vocdoni.net/web3&entryPoints[]=https://gwdev2.vocdoni.net/web3';
                      handleIncomingLink(Uri.parse(link), ctx);
                    },
                  ),
                  ListItem(
                    mainText: "Handle deeplink (A new world)",
                    onTap: () {
                      String link =
                          'vocdoni://vocdoni.app/entity?entityId=0xf6a97d2ec8bb9fabde28b9e377edbd31e92bef3b44040f0752e28896f4baed90&entryPoints[]=https://gwdev1.vocdoni.net/web3&entryPoints[]=https://gwdev2.vocdoni.net/web3';
                      handleIncomingLink(Uri.parse(link), ctx);
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
