import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';
// import 'package:vocdoni/views/organization-info.dart';
// import 'package:vocdoni/widgets/pageTitle.dart';
// import 'package:vocdoni/widgets/section.dart';

class OrganizationsTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;

  OrganizationsTab({this.appState, this.identities});

  // OrganizationsTab() {
  //   makeFakeOrg();
  // }

  // makeFakeOrg() {
  //   var r = new Random();
  //   var i = r.nextInt(999);
  //   identitiesBloc.subscribe(
  //       Organization(entityId: '0xfff$i', name: 'Vocdoni fundation $i'));
  // }

  @override
  Widget build(ctx) {
    List<Organization> orgs = [];

    if (appState != null) {
      int selectedIdentity = appState.selectedIdentity;
      orgs = identities[selectedIdentity].organizations ?? [];
    }
    if (orgs.length == 0) return buildNoOrganizations(ctx);

    return ListView.builder(
        itemCount: orgs.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final org = orgs[index];
          return ListItem(
              text: org.name, onTap: () => onTapOrganization(ctx, org));
        });
  }

  Widget buildNoOrganizations(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("No organizations"),
    );
  }

  onTapOrganization(BuildContext ctx, Organization org) {
    Navigator.pushNamed(ctx, "/organizations/info", arguments: org);
  }
}
