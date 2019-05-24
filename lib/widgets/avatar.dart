import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Avatar extends StatelessWidget {
  final String avatarUrl;
  final double size;

  Avatar({this.avatarUrl, this.size});

  @override
  Widget build(context) {
    return Container(
        width: size,
        height: size,
        decoration: new BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: new Offset(0, 2),
              )
            ],
            color: guideColor,
            shape: BoxShape.circle,
            image: new DecorationImage(
                fit: BoxFit.fill, image: new NetworkImage(avatarUrl))));
  }
}
