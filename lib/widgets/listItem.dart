import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

enum RightItemStyle { DEFAULT, BADGE, BADGE_DANGER }
enum ItemStyle { DEFAULT, DANGER, WARNING, GOOD, HIGHLIGHT }

class ListItem extends StatelessWidget {
  final String text;
  final bool mainTextMultiline;
  final IconData icon;
  final IconData rightIcon;
  final String rightText;
  final RightItemStyle rightTextStyle;
  final void Function() onTap;
  final void Function() onLongPress;
  final ItemStyle style;
  final bool disabled;

  ListItem(
      {this.text,
      this.mainTextMultiline = true,
      this.icon,
      this.rightIcon = FeatherIcons.chevronRight,
      this.rightText,
      this.rightTextStyle = RightItemStyle.DEFAULT,
      this.onTap,
      this.onLongPress,
      this.style = ItemStyle.DEFAULT,
      this.disabled = false});

  @override
  Widget build(context) {
    return InkWell(
        onTap: disabled ? null : onTap,
        onLongPress: disabled ? null : onLongPress,
        child: Container(
            color: getBackroundColor(style, disabled),
            padding: EdgeInsets.all(paddingPage),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  buildIcon(icon: icon),
                  Expanded(
                    child: Text(text,
                        maxLines: mainTextMultiline ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: new TextStyle(
                            fontSize: fontSizeBase,
                            color: getMainColor(style, disabled),
                            fontWeight: FontWeight.w400)),
                  ),
                  buildRightItem(
                      itemStyle: style,
                      icon: rightIcon,
                      text: rightText,
                      rightItemStyle: rightTextStyle)
                ])));
  }

  Color getMainColor(ItemStyle style, bool disabled) {
    Color color = colorDescription;
    if (style == ItemStyle.DANGER) color = colorRed;
    if (style == ItemStyle.WARNING) color = colorOrange;
    if (style == ItemStyle.GOOD) color = colorGreen;
    if (style == ItemStyle.HIGHLIGHT) color = colorBlue;
    if (disabled) color = color.withOpacity(opacityDisabled);
    return color;
  }

  Color getBackroundColor(ItemStyle style, bool disabled) {
    if (style == ItemStyle.DEFAULT) return null;
    return getMainColor(style, disabled).withOpacity(opacityBackgroundColor);
  }

  buildIcon({IconData icon = null}) {
    if (icon == null) return Container();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, spaceElement, 0),
      child: Icon(
        icon,
        color: getMainColor(style, disabled),
        size: iconSizeSmall,
      ),
    );
  }

  buildRightItem(
      {ItemStyle itemStyle,
      IconData icon,
      String text,
      RightItemStyle rightItemStyle}) {
    if (text != null) {
      return buildRightText(itemStyle, text, rightItemStyle);
    }

    if (icon == null) return Container();

    return Padding(
      padding: EdgeInsets.fromLTRB(spaceElement, 0, 0, 0),
      child: Icon(
        icon,
        color: getRightElementColor(itemStyle, rightItemStyle, disabled),
        size: iconSizeSmall,
      ),
    );
  }

  Widget buildRightText(
    ItemStyle itemStyle,
    String text,
    RightItemStyle rightItemStyle,
  ) {
    return Container(
      alignment: Alignment(0, 0),
      padding: EdgeInsets.fromLTRB(paddingBadge, 0, paddingBadge, 0),
      constraints: BoxConstraints(
          minWidth: fontSizeSecondary * 2, minHeight: fontSizeSecondary * 2),
      decoration: new BoxDecoration(
          color: getRightElementBackgroundColor(rightItemStyle),
          borderRadius:
              new BorderRadius.all(Radius.circular(fontSizeSecondary))),
      child: Text(text,
          style: TextStyle(
              fontSize: fontSizeSecondary,
              color: getRightElementColor(itemStyle, rightItemStyle, disabled),
              fontWeight: FontWeight.w400)),
    );
  }

  Color getRightElementColor(
      ItemStyle itemStyle, RightItemStyle rightItemStyle, bool disabled) {
    if (rightItemStyle == RightItemStyle.DEFAULT)
      return getMainColor(itemStyle, disabled)
          .withOpacity(opacitySecondaryElement);
    return Colors.white;
  }

  Color getRightElementBackgroundColor(RightItemStyle style) {
    if (style == RightItemStyle.BADGE_DANGER) return colorRed;
    if (style == RightItemStyle.BADGE) return colorGuide;
    return Colors.transparent;
  }
}
