import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';

class IdentityDetails extends StatelessWidget {
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
                        title:  identities.data[appState.data.selectedIdentity].alias,
                        subtitle: identities.data[appState.data.selectedIdentity].address,
                      ),
                      Section(text: "Your identity"),
                      ListItem(
                        text: "Back up identity",
                        onTap: () {
                          debugPrint("BACK");
                        },
                      ),
                      ListItem(text: "Log out"),
                      ListItem(text: "Test"),
                    ],
                  ),
                );
              });
        });
  }

  onNavigationTap(BuildContext context, int index) {
    if (index == 0) Navigator.popAndPushNamed(context, "/home");
    if (index == 1) Navigator.popAndPushNamed(context, "/organizations");
    if (index == 2) Navigator.popAndPushNamed(context, "/identityDetails");
  }
}
