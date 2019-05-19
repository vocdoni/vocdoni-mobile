import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/data/identities.dart';
import 'package:vocdoni/widgets/cardTitle.dart';
import 'package:vocdoni/widgets/pageTitle.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem feedItem;
  final Organization organization;
  final void Function() onTap;

  FeedItemCard({this.feedItem, this.organization, this.onTap});

  @override
  Widget build(context) {
    return InkWell(
        onTap: onTap,
        child: Container(
            padding: EdgeInsets.fromLTRB(
                pagePadding, cardSpacing, pagePadding, cardSpacing),
            child: Card(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Color(0xff7c94b6),
                          image: new DecorationImage(
                              image: new NetworkImage(feedItem.image),
                              fit: BoxFit.cover)),
                    ),
                  ),
                  CardTitle(
                    title: feedItem.title,
                    subtitle: feedItem.author,
                  )
                ]))));
  }
}
