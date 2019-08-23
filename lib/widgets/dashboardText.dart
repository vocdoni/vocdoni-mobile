import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class DashboardText extends StatelessWidget {
  final String mainText;
  final String secondaryText;
  final Purpose purpose;

  DashboardText({this.mainText, this.secondaryText, this.purpose});

  @override
  Widget build(context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: <Widget>[buildMain(), builSecondary()]);
  }

  buildMain() {
    return Text(mainText,
        style: new TextStyle(
            fontSize: fontSizeTitle,
            color: getColorByPurpose(purpose: purpose),
            fontWeight: fontWeightSemiBold));
  }

  builSecondary() {
    return Text(secondaryText,
        style: new TextStyle(
            fontSize: fontSizeBase,
            color: getColorByPurpose(purpose: purpose),
            fontWeight: fontWeightSemiBold));
  }
}
