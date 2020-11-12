import "package:flutter/material.dart";
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/i18n.dart';

class SettingsMenu extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "main.advancedSettings"),
      ),
      body: Builder(
          builder: (BuildContext context) => ListView(
                children: <Widget>[
                  ListItem(
                    mainText: getText(context, "main.setbootnodesUrl"),
                    onTap: () {
                      Navigator.pushNamed(ctx, "/settings/boot");
                    },
                  ),
                ],
              )),
    );
  }
}
