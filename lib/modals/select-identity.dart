import "package:flutter/material.dart";
import '../util/singletons.dart';
import '../constants/colors.dart';
import '../lang/index.dart';

class SelectIdentityModal extends StatelessWidget {
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
    final identityRows = ((identities ?? []).asMap().keys.map((idx) => ListTile(
              leading: Icon(
                Icons.person,
                size: 40,
              ),
              title: Text(
                identities[idx].alias,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black26),
              ),
              subtitle: Text(
                identities[idx].address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => selected(ctx, idx),
            )))
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: Text("Vocdoni"),
          backgroundColor: mainBackgroundColor,
        ),
        body: ListView(padding: EdgeInsets.zero, children: identityRows));
  }

  selected(BuildContext ctx, int idx) {
    Navigator.pop(ctx, idx);
  }
}
