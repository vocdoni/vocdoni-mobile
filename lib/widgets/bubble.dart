import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Bubble extends StatelessWidget {
  final Widget child;
  final bool selected;
  final Color selectedBackgroundColor;
  final Color backgroundColor;
  final void Function() onTap;

  Bubble(
      {this.child,
      this.selected = false,
      this.onTap,
      this.selectedBackgroundColor = colorBlue,
      this.backgroundColor = colorLightGuide});

  @override
  Widget build(BuildContext context) {
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
