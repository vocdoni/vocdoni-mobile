import "package:flutter/material.dart";
import 'package:vocdoni/widgets/listItem.dart';
import '../util/singletons.dart';
import '../constants/colors.dart';
import '../lang/index.dart';

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
        
        body: ListView.builder(
            itemCount: identities.length,
            itemBuilder: (BuildContext ctxt, int idx) {
              return ListItem(
                text: identities[idx].alias,
                onTap: () => selected(ctx, idx),
              );
            }));
  }

  selected(BuildContext ctx, int idx) {
    appStateBloc.selectIdentity(idx);
    Navigator.pop(ctx);
    Navigator.pushReplacementNamed(ctx, "/identityDetails");
  }
}
