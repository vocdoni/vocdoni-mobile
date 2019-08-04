import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/widgets/avatar.dart';

enum RightTextStyle { DEFAULT, BADGE, BADGE_DANGER }
enum ItemStyle { DEFAULT, DANGER, WARNING, GOOD, HIGHLIGHT }

class ListItem extends StatelessWidget {
  final String mainText;
  final bool iconIsSecondary;
  final String secondaryText;
  final bool mainTextMultiline;
  final bool secondaryTextMultiline;
  final IconData icon;
  final String avatarUrl;
  final IconData rightIcon;
  final String rightText;
  final RightTextStyle rightTextStyle;
  final void Function() onTap;
  final void Function() onLongPress;
  final ItemStyle itemStyle;
  final bool disabled;

  ListItem(
      {this.mainText,
      this.iconIsSecondary = false,
      this.secondaryText,
      this.mainTextMultiline = true,
      this.secondaryTextMultiline = false,
      this.icon,
      this.avatarUrl,
      this.rightIcon = FeatherIcons.chevronRight,
      this.rightText,
      this.rightTextStyle = RightTextStyle.DEFAULT,
      this.onTap,
      this.onLongPress,
      this.itemStyle = ItemStyle.DEFAULT,
      this.disabled = false});

  @override
  Widget build(context) {
    return InkWell(
        onTap: disabled ? null : onTap,
        onLongPress: disabled ? null : onLongPress,
        child: Container(
            color: getBackroundColor(),
            padding: EdgeInsets.all(paddingPage),
            child: iconIsSecondary
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                        buildMainText(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              0, spaceMainAndSecondary, 0, 0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                buildIcon(),
                                Expanded(child: buildSecondaryText()),
                                buildRightItem()
                              ]),
                        )
                      ])
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                        buildIcon(),
                        buildTextsColumn(),
                        buildRightItem()
                      ])));
  }

  buildTextsColumn() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildMainText(),
          secondaryText == null ? Container() : buildSecondaryText(),
        ],
      ),
    );
  }

  buildMainText() {
    return Text(mainText,
        maxLines: mainTextMultiline ? 3 : 1,
        overflow: TextOverflow.ellipsis,
        style: new TextStyle(
            fontSize: fontSizeBase,
            color: getMainColor(),
            fontWeight: FontWeight.w400));
  }

  buildSecondaryText() {
    return Text(secondaryText,
        maxLines: secondaryTextMultiline ? 3 : 1,
        overflow: TextOverflow.ellipsis,
        style: new TextStyle(
            fontSize: fontSizeSecondary,
            color: getSecondaryElementColor(),
            fontWeight: FontWeight.w400));
  }

  buildIcon() {
    if (avatarUrl == null && icon == null) return Container();

    double size = iconIsSecondary || secondaryText == null
        ? iconSizeSmall
        : iconSizeMedium;

    return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, paddingIcon, 0),
        child: avatarUrl == null
            ? Icon(
                icon,
                color: getMainColor(),
                size: size,
              )
            : CircleAvatar(
                backgroundColor: Colors.transparent,//.brown.shade800,
                //child: avatarUrl == null ? Text('AH') : null,
                backgroundImage: NetworkImage(avatarUrl),
              ));
  }

  buildRightItem() {
    if (rightText != null) {
      return buildRightText();
    }

    if (rightIcon == null) return Container();

    return Padding(
      padding: EdgeInsets.fromLTRB(paddingIcon, 0, 0, 0),
      child: Icon(
        rightIcon,
        color: getRightElementColor(),
        size: iconSizeTinny,
      ),
    );
  }

  Widget buildRightText() {
    return Container(
      alignment: Alignment(0, 0),
      padding: EdgeInsets.fromLTRB(paddingBadge, 0, paddingBadge, 0),
      constraints: BoxConstraints(
          minWidth: fontSizeSecondary * 2, minHeight: fontSizeSecondary * 2),
      decoration: new BoxDecoration(
          color: getRightElementBackgroundColor(rightTextStyle),
          borderRadius:
              new BorderRadius.all(Radius.circular(fontSizeSecondary))),
      child: Text(rightText,
          style: TextStyle(
              fontSize: fontSizeSecondary,
              color: getRightElementColor(),
              fontWeight: FontWeight.w400)),
    );
  }

  Color getMainColor() {
    Color color = colorDescription;
    if (itemStyle == ItemStyle.DANGER) color = colorRed;
    if (itemStyle == ItemStyle.WARNING) color = colorOrange;
    if (itemStyle == ItemStyle.GOOD) color = colorGreen;
    if (itemStyle == ItemStyle.HIGHLIGHT) color = colorBlue;
    if (disabled) color = color.withOpacity(opacityDisabled);
    return color;
  }

  Color getBackroundColor() {
    if (itemStyle == ItemStyle.DEFAULT) return null;
    return getMainColor().withOpacity(opacityBackgroundColor);
  }

  Color getSecondaryElementColor() {
    return getMainColor().withOpacity(opacitySecondaryElement);
  }

  Color getRightElementColor() {
    if (rightTextStyle == RightTextStyle.DEFAULT)
      return getSecondaryElementColor().withOpacity(opacitySecondaryElement);
    return Colors.white;
  }

  Color getRightElementBackgroundColor(RightTextStyle style) {
    if (style == RightTextStyle.BADGE_DANGER) return colorRed;
    if (style == RightTextStyle.BADGE) return colorGuide;
    return Colors.transparent;
  }
}
