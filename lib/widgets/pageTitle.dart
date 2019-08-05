import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;

  PageTitle({this.title, this.subtitle, this.titleColor});

  @override
  Widget build(context) {
    Color c = titleColor == null? titleColor: titleColor;
    return Container(
        padding: EdgeInsets.fromLTRB(
            paddingPage, spaceElement, paddingPage, spaceElement),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: new TextStyle(
                      fontSize: 22,
                      color: c,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Text(subtitle,
                  style: new TextStyle(
                      fontSize: 16,
                      color: colorGuide,
                      fontWeight: FontWeight.w400)),
            ]));
  }
}
