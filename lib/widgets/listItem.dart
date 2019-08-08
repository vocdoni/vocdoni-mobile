import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

enum Purpose { NONE, GUIDE, DANGER, WARNING, GOOD, HIGHLIGHT }

class ListItem extends StatelessWidget {
  final String mainText;
  final bool mainTextFullWidth;
  final String secondaryText;
  final bool mainTextMultiline;
  final bool secondaryTextMultiline;
  final IconData icon;
  final String avatarUrl;
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
      this.mainTextFullWidth = false,
      this.secondaryText,
      this.mainTextMultiline = true,
      this.secondaryTextMultiline = false,
      this.icon,
      this.avatarUrl,
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
                          buildMainText(),
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
            fontSize: isTitle ? fontSizeTitle : fontSizeBase,
            color: getMainColor(),
            fontWeight: isBold ? fontWeightBold : fontWeightRegular));
  }

  buildSecondaryText() {
    return Text(secondaryText,
        maxLines: secondaryTextMultiline ? 3 : 1,
        overflow: TextOverflow.ellipsis,
        style: new TextStyle(
            fontSize: fontSizeSecondary,
            color: getSecondaryElementColor(),
            fontWeight: fontWeightRegular));
  }

  buildIcon() {
    if (avatarUrl == null && icon == null) return Container();

    double size = mainTextFullWidth || secondaryText == null
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
            : Container(
                constraints: BoxConstraints(maxWidth: size, maxHeight: size),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent, //.brown.shade800,
                  //child: avatarUrl == null ? Text('AH') : null,
                  backgroundImage: NetworkImage(avatarUrl),
                )));
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
    return getColorByPurpose(purpose);
  }

  Color getBackroundColor() {
    if (purpose == Purpose.NONE || purpose == Purpose.GUIDE) return null;
    return getMainColor().withOpacity(opacityBackgroundColor);
  }

  Color getSecondaryElementColor() {
    return getMainColor().withOpacity(opacitySecondaryElement);
  }

  Color getRightElementColor() {
    if (rightTextIsBadge) return Colors.white;
    if (purpose != Purpose.NONE && purpose != Purpose.GUIDE)
      return getSecondaryElementColor().withOpacity(opacitySecondaryElement);
    else
      return getColorByPurpose(rightTextPurpose);
  }

  Color getRightElementBackgroundColor() {
    if (!rightTextIsBadge) return null;
    return getColorByPurpose(rightTextPurpose);
  }

  Color getColorByPurpose(Purpose purpose) {
    if (purpose == Purpose.NONE) return colorDescription;
    if (purpose == Purpose.GUIDE) return colorGuide;
    if (purpose == Purpose.DANGER) return colorRed;
    if (purpose == Purpose.WARNING) return colorOrange;
    if (purpose == Purpose.GOOD) return colorGreen;
    if (purpose == Purpose.HIGHLIGHT) return colorBlue;
    return colorDescription;
  }
}
