import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class BaseCard extends StatelessWidget {
  final String image;
  final List<Widget> children;

  BaseCard({this.image, this.children});

  @override
  Widget build(context) {
    if (image != null) children.insert(0, buildImage());
    
    return Padding(
        padding: EdgeInsets.fromLTRB(
            paddingPage, spaceCard * 0.5, paddingPage, spaceCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(roundedCornerCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30.0, // has the effect of softening the shadow
                spreadRadius: 0.0, // has the effect of extending the shadow
                offset: Offset(
                  0, // horizontal, move right 10
                  5, // vertical, move down 10
                ),
              )
            ],
            color: colorCardBackround,
          ),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(roundedCornerCard),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children)),
        ));
  }

  buildImage() {
    return AspectRatio(
      aspectRatio: 9 / 4,
      child: Container(
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: Color(0xf70094b6),
              image: new DecorationImage(
                  image: new NetworkImage(image), fit: BoxFit.cover)),
        ),
      ),
    );
  }
}
