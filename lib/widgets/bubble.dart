import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Bubble extends StatelessWidget {
  final Widget child;
  final bool selected;
  Color selectedBackgroundColor;
  Color backgroundColor;
  final void Function() onTap;

  Bubble(
      {this.child,
      this.selected = false,
      this.onTap,
      this.selectedBackgroundColor,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    if (selectedBackgroundColor == null) selectedBackgroundColor = colorBlue;
    if (backgroundColor == null) backgroundColor = colorLightGuide;
    return Padding(
      padding: EdgeInsets.all(spaceElement),
      child: AnimatedContainer(
          child: InkWell(
            onTap: onTap == null ? null : onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(paddingBubble * 2, paddingBubble,
                  paddingBubble * 2, paddingBubble),
              child: child,
            ),
          ),
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(paddingBubble),
              color: selected ? selectedBackgroundColor : backgroundColor)),
    );
  }
}
