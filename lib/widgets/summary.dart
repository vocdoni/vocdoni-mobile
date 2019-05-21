import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Summary extends StatelessWidget {
  final String text;
  final int maxLines;

  Summary({this.text, this.maxLines});

  @override
  Widget build(context) {
    return Container(
        padding: new EdgeInsets.all(pagePadding),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          maxLines: maxLines,
          style: TextStyle(
              fontSize: 16,
              color: descriptionColor,
              fontWeight: lightFontWeight),
        ));
  }
}