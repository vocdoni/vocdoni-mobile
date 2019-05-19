import "package:flutter/material.dart";
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import '../util/singletons.dart';

class IdentitySelectScreen extends StatelessWidget {
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
        onTap: () => onIdentitySelected(ctx, i),
      ));
    }
    return Column(children: list);
  }

  onIdentitySelected(BuildContext ctx, int idx) {
    appStateBloc.selectIdentity(idx);
    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }

  createNew(BuildContext ctx) {
    Navigator.pushNamed(ctx, "/identity/create");
  }
}
