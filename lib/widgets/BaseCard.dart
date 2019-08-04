import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/listItem.dart';

class BaseCard extends StatelessWidget {
  final String headerImageUrl;

  BaseCard({this.headerImageUrl});

  @override
  Widget build(context) {
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
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 9 / 4,
                      child: Container(
                        //height: 200,
                        //width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: Color(0xf70094b6),
                              image: new DecorationImage(
                                  image: new NetworkImage(headerImageUrl),
                                  fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                    ListItem(
                      mainText: "Wher would you like the next retreat?",
                      secondaryText: "Vocdoni",
                      rightText: "Sat, Aug 3 ",
                      iconIsSecondary: true,
                      avatarUrl:
                          "https://icon2.kisspng.com/20171221/see/phoenix-logo-vector-design-5a3c31b00e5f48.7862516515138943200589.jpg",
                    )
                  ]),
            )));
  }
}
