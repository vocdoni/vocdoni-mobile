import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Section extends StatelessWidget {
  final String text;

  Section({String this.text});

  @override
  Widget build(context) {
    return Container(
        padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 16),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Container(height: 1, color: lightGuideColor),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 24),
                  child: Text(text,
                      style: new TextStyle(
                          fontSize: 16,
                          color: guideColor,
                          fontWeight: FontWeight.w400))),
              Expanded(
                child: Container(height: 1, color: lightGuideColor),
              ),
            ]));
  }
}
