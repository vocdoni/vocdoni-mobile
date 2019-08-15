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
  final bool hasBackground;

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
      this.hasBackground = true,
      this.purpose});

  @override
  Widget build(BuildContext context) {
    Color c1 = getColorByPurpose(
      purpose: purpose,
    );
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

    if (!hasBackground) {
      ct = getColorByPurpose(purpose: purpose);
      c1 = Colors.transparent;
      c2 = Colors.transparent;
    }

    double sidePadding = 24;

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
                        leftIconData == null
                            ? Container()
                            : Padding(
                                padding:
                                    EdgeInsets.fromLTRB(0, 0, spaceElement, 0),
                                child: Icon(
                                  leftIconData,
                                  color: ct,
                                ),
                              ),
                        Text(text,
                            style: TextStyle(
                                color: ct,
                                fontWeight: isSmall
                                    ? fontWeightRegular
                                    : fontWeightSemiBold,
                                fontSize: 16)),
                        rightIconData == null
                            ? Container()
                            : Padding(
                                padding:
                                    EdgeInsets.fromLTRB(spaceElement, 0, 0, 0),
                                child: Icon(
                                  rightIconData,
                                  color: ct,
                                ),
                              ),
                      ],
                    ),
                  )),
                ),
              ),
            )));
  }
}
