import "package:flutter/material.dart";
import 'package:dvote_common/widgets/baseAvatar.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/constants/colors.dart';
import 'dart:math' as math;

class DevUiAvatarColor extends StatelessWidget {
  String randomHex() {
    int i = (math.Random().nextDouble() * 0xFFFFFF).toInt();
    String hex = i.toRadixString(16).padLeft(6, "0");
    return '0x' + hex;
  }

  @override
  Widget build(ctx) {
    List<Widget> smallAvatars = List.generate(100, (i) {
      return BaseAvatar(
        avatarUrl: null,
        text: "Abc Def",
        hexSource: randomHex(),
        size: iconSizeSmall,
      );
    });
    List<Widget> mediumAvatars = List.generate(50, (i) {
      return BaseAvatar(
        avatarUrl: null,
        text: "Abc Def",
        hexSource: randomHex(),
        size: iconSizeMedium,
      );
    });
    List<Widget> largeAvatars = List.generate(30, (i) {
      return BaseAvatar(
        avatarUrl: null,
        text: "Abc Def",
        hexSource: randomHex(),
        size: iconSizeLarge,
      );
    });
    List<Widget> hugeAvatars = List.generate(15, (i) {
      return BaseAvatar(
        avatarUrl: null,
        text: "Abc Def",
        hexSource: randomHex(),
        size: iconSizeHuge,
      );
    });
    return Scaffold(
      appBar: TopNavigation(
        title: "Avatar color variants",
      ),
      body: Wrap(
        children: smallAvatars
          ..addAll(mediumAvatars)
          ..addAll(largeAvatars)
          ..addAll(hugeAvatars),
      ),
    );
  }
}
