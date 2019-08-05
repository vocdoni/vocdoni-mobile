import "package:dvote/dvote.dart";
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
// import 'package:vocdoni/data/identities.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/cardTitle.dart';
// import 'package:vocdoni/widgets/pageTitle.dart';
// import 'package:vocdoni/util/api.dart' show Entity;

class FeedItemCard extends StatelessWidget {
  final FeedPost post;
  // final Entity organization;
  final void Function() onTap;

  FeedItemCard({this.post, this.onTap});

  @override
  Widget build(context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            paddingPage, spaceElement, paddingPage, spaceElement),
        child: Card(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 200,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Color(0xff7c94b6),
                        image: new DecorationImage(
                            image: new NetworkImage(post.image),
                            fit: BoxFit.cover)),
                  ),
                ),
                CardTitle(
                  title: post.title,
                  subtitle: post.author.name,
                )
              ]),
        ),
      ),
    );
  }
}
