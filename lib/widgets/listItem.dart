import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/widgets/baseAvatar.dart';

class ListItem extends StatelessWidget {
  final String mainText;
  final String mainTextTag;
  final bool mainTextFullWidth;
  final String secondaryText;
  final int mainTextMultiline;
  final int secondaryTextMultiline;
  final IconData icon;
  final String avatarUrl;
  final String avatarText;
  final String avatarHexSource;
  final IconData rightIcon;
  final String rightText;
  final Purpose rightTextPurpose;
  final bool rightTextIsBadge;
  final void Function() onTap;
  final void Function() onLongPress;
  final Purpose purpose;
  final bool disabled;
  final bool isTitle;
  final bool isBold;

  ListItem(
      {this.mainText,
      this.mainTextTag,
      this.mainTextFullWidth = false,
      this.secondaryText,
      this.mainTextMultiline = 1,
      this.secondaryTextMultiline = 1,
      this.icon,
      this.avatarUrl,
      this.avatarText,
      this.avatarHexSource,
      this.rightIcon = FeatherIcons.chevronRight,
      this.rightText,
      this.rightTextPurpose = Purpose.GUIDE,
      this.rightTextIsBadge = false,
      this.onTap,
      this.onLongPress,
      this.purpose = Purpose.NONE,
      this.disabled = false,
      this.isTitle = false,
      this.isBold = false});

  @override
  Widget build(context) {
    return InkWell(
        onTap: disabled ? null : onTap,
        onLongPress: disabled ? null : onLongPress,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Container(
              color: getBackroundColor(),
              padding: EdgeInsets.fromLTRB(paddingPage, 20, paddingPage, 20),
              child: mainTextFullWidth
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                          buildMainTextWithHero(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                0, spaceMainAndSecondary, 0, 0),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                        ])),
        ));
  }

  buildTextsColumn() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildMainTextWithHero(),
          secondaryText == null
              ? Container()
              : SizedBox(height: spaceMainAndSecondary),
          secondaryText == null ? Container() : buildSecondaryText(),
        ],
      ),
    );
  }

  buildMainText() {
    return Text(mainText,
        maxLines: mainTextMultiline,
        overflow: TextOverflow.ellipsis,
        style: new TextStyle(
            fontSize: isTitle ? fontSizeTitle : fontSizeBase,
            color: getMainColor(),
            fontWeight: isBold ? fontWeightSemiBold : fontWeightRegular));
  }

  buildMainTextWithHero() {
    return mainTextTag == null
        ? buildMainText()
        : Hero(
            tag: mainTextTag,
            child: buildMainText(),
          );
  }

  buildSecondaryText() {
    return Text(secondaryText,
        maxLines: secondaryTextMultiline,
        overflow: TextOverflow.ellipsis,
        style: new TextStyle(
            fontSize: fontSizeSecondary,
            color: getSecondaryElementColor(),
            fontWeight: fontWeightRegular));
  }

  buildIcon() {
    if (avatarUrl == null && icon == null) return Container();

    double iconSize = mainTextFullWidth || secondaryText == null
        ? iconSizeSmall
        : iconSizeMedium;
    double avatarSize = mainTextFullWidth || secondaryText == null
        ? iconSizeSmall + (paddingIcon - paddingAvatar)
        : iconSizeMedium + (paddingIcon - paddingAvatar);

    double padding = avatarUrl == null ? paddingIcon : paddingAvatar;
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, padding, 0),
        child: avatarUrl == null
            ? Icon(
                icon,
                color: getMainColor(),
                size: iconSize,
              )
            : BaseAvatar(
                size: avatarSize,
                text: avatarText,
                hexSource: avatarHexSource,
                avatarUrl: avatarUrl));
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
        size: iconSizeSmall,
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
          color: getRightElementBackgroundColor(),
          borderRadius:
              new BorderRadius.all(Radius.circular(fontSizeSecondary))),
      child: Text(rightText,
          style: TextStyle(
              fontSize: fontSizeSecondary,
              color: getRightElementColor(),
              fontWeight: fontWeightRegular)),
    );
  }

  Color getMainColor() {
    return getColorByPurpose(purpose: purpose);
  }

  Color getBackroundColor() {
    if (purpose == Purpose.NONE) return null;
    return getColorByPurpose(purpose: purpose, isPale: true)
        .withOpacity(opacityBackgroundColor);
  }

  Color getSecondaryElementColor() {
    return getMainColor().withOpacity(opacitySecondaryElement);
  }

  Color getRightElementColor() {
    if (rightTextIsBadge) return Colors.white;
    if (purpose != Purpose.NONE && purpose != Purpose.GUIDE)
      return getSecondaryElementColor().withOpacity(opacitySecondaryElement);
    else
      return getColorByPurpose(purpose: rightTextPurpose);
  }

  Color getRightElementBackgroundColor() {
    if (!rightTextIsBadge) return null;
    return getColorByPurpose(purpose: rightTextPurpose);
  }
}
