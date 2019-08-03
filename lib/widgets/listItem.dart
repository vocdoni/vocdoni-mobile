import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class ListItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final void Function() onTap;
  final void Function() onLongPress;

  ListItem({this.text, this.icon, this.onTap, this.onLongPress});

  @override
  Widget build(context) {
    double iconSize = iconSizeSmall;

    return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
            padding: EdgeInsets.all(pagePadding),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  getIcon(icon: icon),
                  Text(text,
                      style: new TextStyle(
                          fontSize: fontSizeBase,
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

  getIcon({IconData icon = null}) {
    if (icon == null) return Container();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, elementSpacing, 0),
      child: Icon(
        icon,
        color: descriptionColor,
        size: iconSizeSmall,
      ),
    );
  }
}
