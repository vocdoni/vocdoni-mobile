import "package:flutter/material.dart";
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/constants/colors.dart';
import 'dart:math' as math;

class DevUiAvatarColor extends StatelessWidget {
  String randomHex() {
    int i = (math.Random().nextDouble() * 0xFFFFFF).toInt();
    String hex = i.toRadixString(16).padLeft(6);
    return '0x' + hex;
  }

  @override
  Widget build(ctx) {
    final h1 = randomHex();

    final h2 = randomHex();

    final h3 = randomHex();

    final h4 = randomHex();

    return Scaffold(
      appBar: TopNavigation(
        title: "Cards variants",
      ),
      body: ListView(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: getAvatarBackgroundColor(h1),
            foregroundColor: getAvatarTextColor(h1),
            child: Text(getAvatarText(h1)),
          ),
          CircleAvatar(
              backgroundColor: getAvatarBackgroundColor(h2),
              foregroundColor: getAvatarTextColor(h2),
              child: Text(getAvatarText(h1))),
          CircleAvatar(
              backgroundColor: getAvatarBackgroundColor(h3),
              foregroundColor: getAvatarTextColor(h3),
              child: Text(getAvatarText(h1))),
          CircleAvatar(
              backgroundColor: getAvatarBackgroundColor(h4),
              foregroundColor: getAvatarTextColor(h4),
              child: Text(getAvatarText(h1)))
        ],
      ),
    );
  }
}
