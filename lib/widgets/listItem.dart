import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class ListItem extends StatelessWidget {
  final String text;
  final Icon icon;
  final void Function() onTap;

  ListItem({String this.text, Icon this.icon, void Function() this.onTap});

  @override
  Widget build(context) {
    return InkWell(
        onTap: onTap,
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
