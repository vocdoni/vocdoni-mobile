import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class ListItem extends StatelessWidget {
  final String text;
  final Icon icon;
  final void Function() onTap;
  final void Function() onLongPress;

  ListItem({this.text, this.icon, this.onTap, this.onLongPress});

  @override
  Widget build(context) {
    return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
            padding: EdgeInsets.all(pagePadding),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(text,
                      style: new TextStyle(
                          fontSize: 18,
                          color: descriptionColor,
                          fontWeight: FontWeight.w400)),
                  Spacer(flex: 1),
                  Icon(
                    FeatherIcons.chevronRight,
                    color: guideColor,
                    size: 18.0,
                  )
                ])));
  }
}
