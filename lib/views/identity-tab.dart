import "package:flutter/material.dart";
// import 'package:vocdoni/modals/pattern-create-modal.dart';
import 'package:vocdoni/modals/pattern-prompt-modal.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/identity-backup.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:dvote/dvote.dart';

// TODO: REMOVE
import 'package:vocdoni/util/dev/populate.dart';

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
              ? identities[appState.selectedIdentity].identityId
              : "",
        ),
        Section(text: "Your identity"),
        ListItem(
          text: "Back up my identity",
          onTap: () => showIdentityBackup(ctx),
        ),
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

  showIdentityBackup(BuildContext ctx) async {
    final identity =
        identitiesBloc.current[appStateBloc.current.selectedIdentity];

    var result = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) =>
                PaternPromptModal(identity.keys[0].encryptedMnemonic)));

    if (result == null || result is InvalidPatternError) {
      showErrorMessage("The pattern you entered is not valid", context: ctx);
      return;
    }
    final mnemonic =
        await decryptString(identity.keys[0].encryptedMnemonic, result);

    Navigator.pushNamed(ctx, "/identity/backup",
        arguments: IdentityBackupArguments(identity.alias, mnemonic));
  }

  onLogOut(BuildContext ctx) async {
    Navigator.pushNamedAndRemoveUntil(
        ctx, "/identity/select", (Route _) => false);
  }
}
