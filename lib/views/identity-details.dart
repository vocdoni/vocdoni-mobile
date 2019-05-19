import "package:flutter/material.dart";
import 'package:vocdoni/modals/select-identity.dart';
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
                        title:
                            appState.data != null && identities.data.length > 0
                                ? identities
                                    .data[appState.data.selectedIdentity].alias
                                : "",
                        subtitle:
                            appState.data != null && identities.data.length > 0
                                ? identities
                                    .data[appState.data.selectedIdentity]
                                    .address
                                : "",
                      ),
                      Section(text: "Your identity"),
                      ListItem(
                        text: "Back up identity",
                        onTap: () {
                          debugPrint("BACK");
                        },
                      ),
                      ListItem(
                          text: "Log out",
                          onTap: () {
                            selectIdentity(ctx);
                          }),
                    ],
                  ),
                );
              });
        });
  }

  selectIdentity(BuildContext ctx) async {
    Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => IdentitySelect()),
    );
  }
}
