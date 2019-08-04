import "package:flutter/material.dart";
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class DevUiCard extends StatelessWidget {
  @override
  Widget build(ctx) {
    String headerImg =
        "https://images.unsplash.com/photo-1535485654825-17b2e804ba9c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1650&q=80";
    return Scaffold(
        appBar: TopNavigation(
          title: "Cards variants",
        ),
        body: ListView(
          children: <Widget>[
            BaseCard(headerImageUrl: headerImg,),
            BaseCard(headerImageUrl: headerImg,),
            BaseCard(headerImageUrl: headerImg,),
            BaseCard(headerImageUrl: headerImg,)

          ],
        ),

        );
  }
}
