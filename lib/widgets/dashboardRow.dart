import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class DashboardRow extends StatelessWidget {
  final List<Widget> children;

  DashboardRow({this.children});

  @override
  Widget build(context) {
    return Padding(
      padding:  EdgeInsets.fromLTRB(paddingPage,spaceElement,paddingPage,spaceElement),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:children),
    );
  }
}
