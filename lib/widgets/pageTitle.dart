import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  PageTitle({String this.title, String this.subtitle});

  @override
  Widget build(context) {
    return Container(
        padding: EdgeInsets.fromLTRB(pagePadding, elementSpacing, pagePadding, elementSpacing),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: new TextStyle(
                      fontSize: 22,
                      color: titleColor,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Text(subtitle,
                  style: new TextStyle(
                      fontSize: 16,
                      color: guideColor,
                      fontWeight: FontWeight.w400)),
            ]));
  }
}
