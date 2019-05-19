import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class CardTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  CardTitle({this.title, this.subtitle});

  @override
  Widget build(context) {
    return Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(subtitle,
                  style: new TextStyle(
                      fontSize: 12,
                      color: guideColor,
                      fontWeight: FontWeight.w400)),
              SizedBox(height: 8),
              Text(title,
                  style: new TextStyle(
                      fontSize: 16,
                      color: titleColor,
                      fontWeight: FontWeight.w700)),
            ]));
  }
}
