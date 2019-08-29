import 'dart:math';

import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class BaseAvatar extends StatelessWidget {
  final String text;
  final String avatarUrl;
  final String hexSource;
  final void Function() onTap;
  final double size;

  const BaseAvatar(
      {this.text, this.avatarUrl, this.hexSource, this.onTap, this.size});

  @override
  Widget build(BuildContext context) {
    bool isValidAvatarUrl = avatarUrl != null && avatarUrl != "";

    return Stack(children: [
      Container(
          constraints: BoxConstraints(
              maxWidth: size, maxHeight: size, minWidth: size, minHeight: size),
          child: CircleAvatar(
            backgroundColor: getAvatarBackgroundColor(hexSource),
            foregroundColor: getAvatarTextColor(
              hexSource,
            ),
            child: Text(
              getAvatarText(text),
              style: TextStyle(
                  fontWeight: fontWeightSemiBold,
                  fontSize: getFontSize(size, getAvatarText(text))),
            ),
          )),
      Container(
          constraints: BoxConstraints(
              maxWidth: size, maxHeight: size, minWidth: size, minHeight: size),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: isValidAvatarUrl ? NetworkImage(avatarUrl) : null,
          )),
    ]);
  }

  getFontSize(size, text) {
    double f = size * (1 / log(size));

    return text.length == 1 ? f * 1.8 : f * 1.3;
  }

  getAvatarText(String text) {
    if (text == null || text == "") return "";
    return text.substring(0, 1);
  }
}
