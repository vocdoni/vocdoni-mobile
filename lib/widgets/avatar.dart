import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Avatar extends StatelessWidget {
  final String avatarUrl;

  Avatar({this.avatarUrl});

  @override
  Widget build(context) {
    return Padding(
      padding: EdgeInsets.all(elementSpacing),
      child: Center(
        child: new Container(
            width: 96,
            height: 96,
            decoration: new BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: new Offset(0, 2),
                  )
                ],
                shape: BoxShape.circle,
                image: new DecorationImage(
                    fit: BoxFit.fill, image: new NetworkImage(avatarUrl)))),
      ),
    );
  }
}
