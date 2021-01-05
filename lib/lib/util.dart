import 'package:dvote_common/constants/colors.dart';
import 'package:flutter/material.dart';

Widget extractBoldText(String rawText, {Pattern separator, TextStyle style}) {
  final text = rawText.split(separator ?? RegExp(r"(?=({{|}}))"));
  final spans = List<TextSpan>();
  text.forEach((element) {
    if (element.startsWith("{"))
      spans.add(
        TextSpan(
            text: element.replaceAll(RegExp(r"({{|}})"), ""),
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    else
      spans.add(
        TextSpan(text: element.replaceAll(RegExp(r"({{|}})"), "")),
      );
  });
  return RichText(
    text: TextSpan(
      children: spans,
      style: style ??
          TextStyle(
            fontSize: 18,
            fontWeight: fontWeightLight,
            fontFamily: "Open Sans",
            color: colorDescription,
          ),
    ),
  );
}
