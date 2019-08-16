import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

enum BaseButtonStyle {
  FILLED,
  OUTLINE,
  OUTLINE_WHITE,
  NO_BACKGROUND,
  NO_BACKGROUND_WHITE
}

class BaseButton extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final Icon icon;
  final bool isDisabled;
  final bool isSmall;
  final double maxWidth;
  final Purpose purpose;
  final IconData leftIconData;
  final IconData rightIconData;
  final BaseButtonStyle style;

  const BaseButton(
      {this.text,
      this.onTap,
      this.icon,
      this.isDisabled = false,
      this.isSmall = false,
      this.maxWidth,
      this.leftIconData,
      this.rightIconData,
      this.purpose,
      this.style = BaseButtonStyle.FILLED});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = getColorByPurpose(
      purpose: purpose,
    );
    Color outlineColor = Colors.transparent;
    Color textColor = Colors.white;

    if (style == BaseButtonStyle.OUTLINE) {
      backgroundColor = Colors.transparent;
      outlineColor = getColorByPurpose(
        purpose: purpose,
      );
      textColor = outlineColor;
    }

    if (style == BaseButtonStyle.OUTLINE_WHITE) {
      outlineColor = Colors.white;
      backgroundColor = Colors.transparent;
      textColor = Colors.white;
    }

    if (style == BaseButtonStyle.NO_BACKGROUND) {
      backgroundColor = Colors.transparent;
      outlineColor = Colors.transparent;
      textColor = getColorByPurpose(
        purpose: purpose,
      );
    }

    if (style == BaseButtonStyle.NO_BACKGROUND) {
      backgroundColor = Colors.transparent;
      outlineColor = Colors.transparent;
      textColor = getColorByPurpose(
        purpose: purpose,
      );
    }

    if (style == BaseButtonStyle.NO_BACKGROUND_WHITE) {
      backgroundColor = Colors.transparent;
      outlineColor = Colors.transparent;
      textColor = Colors.white;
    }

    bool hasNoBackground = style == BaseButtonStyle.NO_BACKGROUND ||
        style == BaseButtonStyle.NO_BACKGROUND;

    double sidePadding = hasNoBackground ? 0 : 24;

    return Align(
        alignment: Alignment.center,
        child: Opacity(
          opacity: isDisabled ? opacityDisabled : 1,
          child: Container(
              height: isSmall ? 32 : 48,
              constraints: maxWidth == null
                  ? null
                  : BoxConstraints(maxWidth: 150, minHeight: 32),
              child: Material(
                color: backgroundColor,
                borderOnForeground: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(width: 2.0, color: outlineColor)),
                child: InkWell(
                  splashColor: isDisabled ? Colors.transparent : null,
                  onTap: () => isDisabled ? null : onTap(),
                  child: SizedBox(
                    child: Center(
                        child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          buildIcon(
                              iconData: leftIconData,
                              color: textColor,
                              isLeft: true,
                              size: isSmall ? iconSizeTinny : iconSizeSmall),
                          text == null
                              ? Container()
                              : Text(text,
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: isSmall
                                          ? fontWeightRegular
                                          : fontWeightSemiBold,
                                      fontSize: 16)),
                          buildIcon(
                              iconData: rightIconData,
                              color: textColor,
                              isLeft: false,
                              size: isSmall ? iconSizeTinny : iconSizeSmall),
                        ],
                      ),
                    )),
                  ),
                ),
              )),
        ));
  }

  buildIcon({IconData iconData, Color color, bool isLeft, double size}) {
    return iconData == null
        ? Container()
        : Padding(
            padding: isLeft
                ? EdgeInsets.fromLTRB(0, 0, spaceElement, 0)
                : EdgeInsets.fromLTRB(spaceElement, 0, 0, 0),
            child: Icon(
              iconData,
              size: size,
              color: color,
            ),
          );
  }
}
