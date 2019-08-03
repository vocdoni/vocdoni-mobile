import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Section extends StatelessWidget {
  final String text;
  final bool withDectoration;

  Section({String this.text, this.withDectoration = true});

  @override
  Widget build(context) {
    Color decorationColor = withDectoration? colorLightGuide:Colors.transparent;
     
    return Container(
        padding: EdgeInsets.fromLTRB(paddingPage, 24, paddingPage, 16),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Container(height: 1, color: decorationColor),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 24),
                  child: Text(text,
                      style: new TextStyle(
                          fontSize: 16,
                          color: colorGuide,
                          fontWeight: FontWeight.w400))),
              Expanded(
                child: Container(height: 1, color: decorationColor),
              ),
            ]));
  }
}
