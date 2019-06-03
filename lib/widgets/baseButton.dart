import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class BaseButton extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final Icon icon;
  final Color color;
  final bool secondary;
  final bool isDisabled;

  const BaseButton(
      {this.text,
      this.onTap,
      this.icon,
      this.color,
      this.secondary = false,
      this.isDisabled = false});

  @override
  Widget build(BuildContext context) {
    Color c1 = color == null ? blueColor : color;
    Color c2 = Colors.transparent;
    Color ct = Colors.white;

    if(isDisabled){ 
      c1 = c1.withOpacity(0.4);
    }

    if (secondary) {
      c2 = c1;
      c1 = Colors.transparent;
      ct = c2;
    }

    return Align(
        alignment: Alignment.center,
        child: Container(
            constraints: BoxConstraints(maxWidth: 150, minHeight: 32),
            child: Material(
              color: c1,
              borderOnForeground: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(width: 2.0, color: c2)),
              child: InkWell(
                splashColor: isDisabled ? Colors.transparent : null,
                onTap: () => isDisabled ? onTap : null,
                child: SizedBox(
                  child: Center(
                      child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        elementSpacing, 0, elementSpacing, 0),
                    child: Text(text,
                        style: TextStyle(
                            color: ct,
                            fontWeight: semiBoldFontWeight,
                            fontSize: 16)),
                  )),
                ),
              ),
            )));
  }
}
