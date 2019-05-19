import "package:flutter/material.dart";
import 'package:vocdoni/views/identity-welcome.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import '../util/singletons.dart';

class IdentitySelect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                return listContent(context, appState.data, identities.data);
              });
        });
  }

  Widget listContent(
      BuildContext ctx, AppState appState, List<Identity> identities) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Section(text: "Select an identity"),
        buildIdentities(ctx, identities),
        ListItem(text: "Create a new one", onTap: () => createNew(ctx)),
      ],
    ));
  }

  buildIdentities(BuildContext ctx, identities) {
    List<Widget> list = new List<Widget>();
    if (identities == null) return Column(children: list);

    for (var i = 0; i < identities.length; i++) {
      list.add(ListItem(
        text: identities[i].alias,
        onTap: () => selected(ctx, i),
      ));
    }
    return Column(children: list);
  }

  selected(BuildContext ctx, int idx) {
    appStateBloc.selectIdentity(idx);
    Navigator.pop(ctx);
    Navigator.pushReplacementNamed(ctx, "/identityDetails");
  }

  createNew(BuildContext ctx) {
    Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (BuildContext context) => IdentityWelcome()));
  }
}
