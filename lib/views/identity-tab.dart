import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/views/identity-backup-page.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:dvote/dvote.dart';

class IdentityTab extends StatefulWidget {
  IdentityTab();

  @override
  _IdentityTabState createState() => _IdentityTabState();
}

class _IdentityTabState extends State<IdentityTab> {
  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("IdentityTab");
  }

  @override
  Widget build(ctx) {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) return buildEmpty(ctx);

    // Rebuild whenever the identity is updated
    return ChangeNotifierProvider.value(
      value: currentAccount.identity,
      child: Builder(builder: (ctx) {
        if (currentAccount.identity.hasError ||
            !currentAccount.identity.hasValue) return buildEmpty(ctx);

        return ListView(
          children: <Widget>[
            ListItem(
                mainText: currentAccount.identity.value.alias,
                secondaryText: currentAccount.identity.value.identityId,
                isTitle: true,
                isBold: true,
                rightIcon: FeatherIcons.copy,
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: currentAccount.identity.value.identityId));
                  showMessage("Identity ID copied on the clipboard",
                      context: ctx, purpose: Purpose.GOOD);
                }),
            Section(text: "Your identity"),
            ListItem(
              mainText: "Back up my identity",
              onTap: () => showIdentityBackup(ctx),
            ),
            ListItem(
                mainText: "Log out",
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
      }),
    );
  }

  Widget buildEmpty(BuildContext ctx) {
    return Center(
      child: Text("(No identity)"),
    );
  }

  showIdentityBackup(BuildContext ctx) async {
    final encryptedMnemonic =
        globalAppState.currentAccount.identity.value.keys[0].encryptedMnemonic;

    var result = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaternPromptModal(encryptedMnemonic)));

    if (result == null)
      return;
    else if (result is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
      return;
    }

    final mnemonic = await decryptString(encryptedMnemonic, result);

    Navigator.pushNamed(ctx, "/identity/backup",
        arguments: IdentityBackupArguments(
            globalAppState.currentAccount.identity.value.alias, mnemonic));
  }

  onLogOut(BuildContext ctx) async {
    Navigator.pushNamedAndRemoveUntil(
        ctx, "/identity/select", (Route _) => false);
  }

  onDevelopmentTesting(BuildContext ctx) async {
    Navigator.pushNamed(ctx, "/dev");
  }
}
