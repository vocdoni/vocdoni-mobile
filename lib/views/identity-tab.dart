import "package:flutter/material.dart";
import 'package:vocdoni/modals/create-pattern-modal.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/identity-backup.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode

// TODO: REMOVE
import 'package:vocdoni/data/dev/populate.dart';

class IdentityTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;

  IdentityTab({this.appState, this.identities});

  @override
  Widget build(ctx) {
    if (appState == null || identities == null || identities.length == null)
      return buildEmpty(ctx);

    return ListView(
      children: <Widget>[
        PageTitle(
          title: appState != null && identities.length > 0
              ? identities[appState.selectedIdentity].alias
              : "",
          subtitle: appState != null && identities.length > 0
              ? identities[appState.selectedIdentity].address
              : "",
        ),
        Section(text: "Your identity"),
        ListItem(
            text: "Back up identity",
            onTap: () => Navigator.pushNamed(ctx, "/identity/backup",
                arguments: IdentityBackupArguments(appState, identities)),
            onLongPress: () async {
              String pattern = await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => CreatePatternModal(
                            canGoBack: true,
                          )));
              if (pattern == null) {
                showMessage("Pattern was cancelled", context: ctx);
              } else {
                showSuccessMessage("Pattern has been set to $pattern",
                    context: ctx);
              }
            }),
        ListItem(
            text: "Identities",
            onTap: () {
              onLogOut(ctx);
            }),
        kReleaseMode // TODO: DEV BUTTON OUT
            ? Container()
            : ListItem(
                text: "[DEV] Add test organizations",
                onTap: () async {
                  // TODO: REMOVE
                  try {
                    await populateSampleData();
                    showMessage("Completed", context: ctx);
                    await identitiesBloc.readState();
                    await newsFeedsBloc.readState();
                  } catch (err) {
                    showErrorMessage(err?.message ?? err, context: ctx);
                  }
                }),
      ],
    );
  }

  Widget buildEmpty(BuildContext ctx) {
    return Center(
      child: Text("(No identity)"),
    );
  }

  onLogOut(BuildContext ctx) async {
    Navigator.pushNamedAndRemoveUntil(
        ctx, "/identity/select", (Route _) => false);
  }
}
