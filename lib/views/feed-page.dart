import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/organization-activity.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';

class FeedPage extends StatelessWidget {
  final Organization organization;
  final FeedItem feedItem;

  FeedPage({this.organization, this.feedItem});

  @override
  Widget build(context) {
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                return Scaffold(
                 
                  body: ListView(
                    children: <Widget>[
                      PageTitle(
                        title: feedItem.title,
                        subtitle: feedItem.author,
                      ),
                    ],
                  ),
                );
              });
        });
  }
}
