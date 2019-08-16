import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class BaseButton extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final Icon icon;
  final bool secondary;
  final bool isDisabled;
  final bool isSmall;
  final double maxWidth;
  final Purpose purpose;
  final IconData leftIconData;
  final IconData rightIconData;
  final withoutBackground;
  final Color color;

  const BaseButton(
      {this.text,
      this.onTap,
      this.icon,
      this.secondary = false,
      this.isDisabled = false,
      this.isSmall = false,
      this.maxWidth,
      this.leftIconData,
      this.rightIconData,
      this.withoutBackground = false,
      this.color,
      this.purpose});

  @override
  Widget build(BuildContext context) {
    Color c1 = color == null
        ? getColorByPurpose(
            purpose: purpose,
          )
        : color;
    Color c2 = Colors.transparent;
    Color ct = Colors.white;

    if (isDisabled) {
      c1 = c1.withOpacity(0.4);
    }

    if (secondary) {
      c2 = c1;
      c1 = Colors.transparent;
      ct = c2;
    }

    if (withoutBackground) {
      ct = c1;
      c1 = Colors.transparent;
      c2 = Colors.transparent;
    }

    double sidePadding = withoutBackground ? 0 : 24;

    return Align(
        alignment: Alignment.center,
        child: Container(
            height: isSmall ? 32 : 48,
            constraints: maxWidth == null
                ? null
                : BoxConstraints(maxWidth: 150, minHeight: 32),
            child: Material(
              color: c1,
              borderOnForeground: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(width: 2.0, color: c2)),
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
                            color: ct,
                            isLeft: true,
                            size: isSmall ? iconSizeTinny : iconSizeSmall),
                        text == null
                            ? Container()
                            : Text(text,
                                style: TextStyle(
                                    color: ct,
                                    fontWeight: isSmall
                                        ? fontWeightRegular
                                        : fontWeightSemiBold,
                                    fontSize: 16)),
                        buildIcon(
                            iconData: rightIconData,
                            color: ct,
                            isLeft: false,
                            size: isSmall ? iconSizeTinny : iconSizeSmall),
                      ],
                    ),
                  )),
                ),
              ),
            )));
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
