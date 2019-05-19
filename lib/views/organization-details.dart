import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';

class OrganiztionDetails extends StatelessWidget {
  final Organization organization;

  OrganiztionDetails({this.organization});

  @override
  Widget build(context) {
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                return Scaffold(
                  bottomNavigationBar: BottomNavigation(),
                  body: ListView(
                    children: <Widget>[
                      PageTitle(
                        title: organization.name,
                        subtitle: organization.entityId,
                      ),
                      Section(text: "Actions"),
                      ListItem(
                        text: "Subscribe",
                        onTap: () {
                          debugPrint("Subscriing?");
                        },
                      ),
                    ],
                  ),
                );
              });
        });
  }

}
