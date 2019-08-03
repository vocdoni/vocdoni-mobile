import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

enum RightItemStyle { DEFAULT, BADGE, BADGE_DANGER }

class ListItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final IconData rightIcon;
  final String rightText;
  final RightItemStyle rightTextStyle;
  final void Function() onTap;
  final void Function() onLongPress;

  ListItem(
      {this.text,
      this.icon,
      this.rightIcon = FeatherIcons.chevronRight,
      this.rightText,
      this.rightTextStyle = RightItemStyle.DEFAULT,
      this.onTap,
      this.onLongPress});

  @override
  Widget build(context) {
    double iconSize = iconSizeSmall;

    return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
            padding: EdgeInsets.all(paddingPage),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  buildIcon(icon: icon),
                  Text(text,
                      style: new TextStyle(
                          fontSize: fontSizeBase,
                          color: descriptionColor,
                          fontWeight: FontWeight.w400)),
                  Spacer(flex: 1),
                  buildRightItem(
                      icon: rightIcon, text: rightText, style: rightTextStyle)
                ])));
  }

  buildIcon({IconData icon = null}) {
    if (icon == null) return Container();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, spaceElement, 0),
      child: Icon(
        icon,
        color: descriptionColor,
        size: iconSizeSmall,
      ),
    );
  }

  buildRightItem({IconData icon, String text, RightItemStyle style}) {
    if (text != null) {
      return buildRightText(text, style);
    }
    //if (icon == null) return Container();

    return Padding(
      padding: EdgeInsets.fromLTRB(spaceElement, 0, 0, 0),
      child: Icon(
        icon,
        color: guideColor,
        size: iconSizeSmall,
      ),
    );
  }

  Widget buildRightText(String text, RightItemStyle style) {
    return Container(
      alignment: Alignment(0, 0),
      padding: EdgeInsets.fromLTRB(paddingBadge, 0, paddingBadge, 0),
      constraints: BoxConstraints(
          minWidth: fontSizeSecondary * 2, minHeight: fontSizeSecondary * 2),
      decoration: new BoxDecoration(
          color: getRightElementBackgroundColor(style),
          borderRadius:
              new BorderRadius.all(Radius.circular(fontSizeSecondary))),
      child: Text(text,
          style: TextStyle(
              fontSize: fontSizeSecondary,
              color: getRightElementColor(style),
              fontWeight: FontWeight.w400)),
    );
  }

  Color getRightElementColor(RightItemStyle style) {
    if (style == RightItemStyle.DEFAULT) return guideColor;
    return Colors.white;
  }

  Color getRightElementBackgroundColor(RightItemStyle style) {
    if (style == RightItemStyle.BADGE_DANGER) return redColor;
    if (style == RightItemStyle.BADGE) return guideColor;
    return Colors.transparent;
  }
}
