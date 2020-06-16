import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/views/identity-backup-page.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:dvote/crypto/encryption.dart';

class HomeIdentityTab extends StatefulWidget {
  HomeIdentityTab();

  @override
  _HomeIdentityTabState createState() => _HomeIdentityTabState();
}

class _HomeIdentityTabState extends State<HomeIdentityTab> {
  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("HomeIdentityTab");
  }

  @override
  Widget build(ctx) {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) return buildEmpty(ctx);

    // Rebuild whenever the identity is updated
    return EventualBuilder(
      notifier: currentAccount.identity,
      builder: (ctx, _, __) {
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
                  showMessage(
                      getText(context, "Identity ID copied on the clipboard"),
                      context: ctx,
                      purpose: Purpose.GOOD);
                }),
            Section(text: getText(context, "Your identity")),
            ListItem(
              mainText: getText(context, "Back up my identity"),
              onTap: () => showIdentityBackup(ctx),
            ),
            ListItem(
                mainText: getText(context, "Log out"),
                onTap: () {
                  onLogOut(ctx);
                }),
            kReleaseMode // TODO: DEV BUTTON OUT
                ? Container()
                : ListItem(
                    mainText: getText(context, "Development testing"),
                    onTap: () {
                      onDevelopmentTesting(ctx);
                    })
          ],
        );
      },
    );
  }

  Widget buildEmpty(BuildContext ctx) {
    return Center(
      child: Text(getText(context, "(No identity)")),
    );
  }

  showIdentityBackup(BuildContext ctx) async {
    final encryptedMnemonic =
        globalAppState.currentAccount.identity.value.keys[0].encryptedMnemonic;

    var patternEncryptionKey = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) =>
                PatternPromptModal(globalAppState.currentAccount)));

    if (patternEncryptionKey == null)
      return;
    else if (patternEncryptionKey is InvalidPatternError) {
      showMessage(getText(context, "The pattern you entered is not valid"),
          context: ctx, purpose: Purpose.DANGER);
      return;
    }

    final mnemonic = await Symmetric.decryptStringAsync(
        encryptedMnemonic, patternEncryptionKey);

    Navigator.pushNamed(ctx, "/identity/backup",
        arguments: IdentityBackupArguments(
            globalAppState.currentAccount.identity.value.alias, mnemonic));
  }

  onLogOut(BuildContext ctx) async {
    globalAppState.currentAccount?.cleanEphemeral();

    Navigator.pushNamedAndRemoveUntil(
        ctx, "/identity/select", (Route _) => false);
  }

  onDevelopmentTesting(BuildContext ctx) async {
    Navigator.pushNamed(ctx, "/dev");
  }
}