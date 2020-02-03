import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class DashboardItem extends StatelessWidget {
  final String label;
  final Widget item;

  DashboardItem({this.label, this.item});

  @override
  Widget build(context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[buildLabel(), SizedBox(height: spaceElement), item]);
  }

  buildLabel() {
    return Text(label,
        overflow: TextOverflow.ellipsis,
        style: new TextStyle(
            fontSize: fontSizeSecondary,
            color: colorGuide,
            fontWeight: fontWeightLight));
  }

  buildItem() {
    return Container(
      child: item,
      height: 48,
    );
  }
}
