import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/modals/pattern-prompt-modal.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/identity-backup.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:dvote/dvote.dart';

class IdentityTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;

  IdentityTab({this.appState, this.identities});

  @override
  Widget build(ctx) {
    if (appState == null || identities == null || identities.length == null)
      return buildEmpty(ctx);

    Identity account = identitiesBloc.getCurrentAccount();

    return ListView(
      children: <Widget>[
        ListItem(
            mainText: account.alias,
            secondaryText: account.identityId,
            isTitle: true,
            isBold: true,
            rightIcon: FeatherIcons.copy,
            onTap: () {
              Clipboard.setData(ClipboardData(text: account.identityId));
              showMessage("Identity ID copied on the clipboard",
                  context: ctx, purpose: Purpose.GOOD);
            }),
        Section(text: "Your identity"),
        ListItem(
          mainText: "Back up my identity",
          onTap: () => showIdentityBackup(ctx),
        ),
        ListItem(
            mainText: "Identities",
            onTap: () {
              onLogOut(ctx);
            }),
        kReleaseMode // TODO: DEV BUTTON OUT
            ? Container()
            : ListItem(
                mainText: "Development testing",
                onTap: () {
                  onDevelopmentTesting(ctx);
                })
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

    if (result == null) return;
    else if (result is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
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

  onDevelopmentTesting(BuildContext ctx) async {
    Navigator.pushNamed(ctx, "/dev");
  }
}
