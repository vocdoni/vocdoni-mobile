import 'dart:math';

import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';

class Organizations extends StatelessWidget {

  Organizations(){
    makeFakeOrg();
  }

  makeFakeOrg() {
    var r = new Random();
    var i = r.nextInt(999);
    identitiesBloc.subscribe(Organization(
        entityId: '0xfff$i',
        name: 'Vocdoni fundation $i'));
  }

  @override
  Widget build(context) {
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                List<Organization> orgs = identities
                    .data[appState.data.selectedIdentity].organizations;
                return Scaffold(
                    bottomNavigationBar: BottomNavigation(),
                    body: new ListView.builder(
                        itemCount: orgs.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          return ListItem(
                            text: orgs[index].name,
                          );
                        }));
              });
        });
  }

  onNavigationTap(BuildContext context, int index) {
    if (index == 0) Navigator.popAndPushNamed(context, "/home");
    if (index == 1) Navigator.popAndPushNamed(context, "/organizations");
    if (index == 2) Navigator.popAndPushNamed(context, "/identityDetails");
  }
}
