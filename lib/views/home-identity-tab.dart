import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/views/identity-backup-page.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeIdentityTab extends StatefulWidget {
  HomeIdentityTab();

  @override
  _HomeIdentityTabState createState() => _HomeIdentityTabState();
}

class _HomeIdentityTabState extends State<HomeIdentityTab> {
  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("HomeIdentityTab");
  }

  @override
  Widget build(ctx) {
    // Rebuild whenever the identity is updated
    return EventualBuilder(
      notifiers: [
        Globals.appState.currentAccount.identity,
        Globals.appState.selectedAccount
      ],
      builder: (ctx, _, __) {
        final currentAccount = Globals.appState.currentAccount;
        if (currentAccount == null) return buildEmpty(ctx);
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
                      getText(context, "main.identityIdCopiedOnTheClipboard"),
                      context: ctx,
                      purpose: Purpose.GOOD);
                }),
            Section(text: getText(context, "main.general")),
            ListItem(
              mainText: getText(context, "main.backUpMyIdentity"),
              onTap: () => showIdentityBackup(ctx),
              icon: FeatherIcons.archive,
            ),
            ListItem(
                mainText: getText(context, "main.help"),
                icon: FeatherIcons.lifeBuoy,
                onTap: () {
                  canLaunch(HELP_URL).then((ok) {
                    if (ok) launch(HELP_URL);
                  });
                }),
            ListItem(
                mainText: getText(context, "main.logOut"),
                icon: FeatherIcons.logOut,
                onTap: () {
                  onLogOut(ctx);
                }),
            ListItem(
                mainText: getText(context, "main.settings"),
                icon: FeatherIcons.settings,
                onTap: () {
                  onSettings(ctx);
                }),
            !kReleaseMode // TODO: DEV BUTTON OUT
                ? Container()
                : ListItem(
                    mainText: getText(context, "main.developmentTesting"),
                    icon: FeatherIcons.info,
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
      child: Text(getText(context, "main.noIdentity")),
    );
  }

  showIdentityBackup(BuildContext ctx) async {
    final encryptedMnemonic = Globals
        .appState.currentAccount.identity.value.keys[0].encryptedMnemonic;

    var patternEncryptionKey = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) =>
                PatternPromptModal(Globals.appState.currentAccount)));

    if (patternEncryptionKey == null)
      return;
    else if (patternEncryptionKey is InvalidPatternError) {
      showMessage(getText(context, "main.thePatternYouEnteredIsNotValid"),
          context: ctx, purpose: Purpose.DANGER);
      return;
    }

    final mnemonic = await Symmetric.decryptStringAsync(
        encryptedMnemonic, patternEncryptionKey);

    Navigator.pushNamed(ctx, "/identity/backup",
        arguments: IdentityBackupArguments(
            Globals.appState.currentAccount.identity.value.alias, mnemonic));
  }

  onLogOut(BuildContext ctx) async {
    Globals.appState.currentAccount?.cleanEphemeral();

    Navigator.pushNamedAndRemoveUntil(
        ctx, "/identity/select", (Route _) => false);
  }

  onDevelopmentTesting(BuildContext ctx) async {
    Navigator.pushNamed(ctx, "/dev");
  }

  onSettings(BuildContext ctx) async {
    Navigator.pushNamed(ctx, "/settings");
  }
}
