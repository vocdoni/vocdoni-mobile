import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class BaseCard extends StatelessWidget {
  final String image;
  final List<Widget> children;
  final void Function() onTap;

  BaseCard({this.image, this.children, this.onTap});

  @override
  Widget build(context) {
    List<Widget> items = [];
    if (image != null) items.insert(0, buildImage());
    if (children != null) items = new List.from(items)..addAll(children);

    return Padding(
        padding: EdgeInsets.fromLTRB(
            paddingPage, spaceCard * 0.5, paddingPage, spaceCard * 0.5),
        child: Container(
          //padding: EdgeInsets.fromLTRB(0, image == null  ? 6 : 0, 0, children != null  ? 6:0),
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
              child: InkWell(
                onTap: onTap,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items),
              )),
        ));
  }

  buildImage() {
    return AspectRatio(
      aspectRatio: 9 / 4,
      child: Container(
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: Color(0xFFAADDFF),
              image: new DecorationImage(
                  image: new NetworkImage(image), fit: BoxFit.cover)),
        ),
      ),
    );
  }
}
