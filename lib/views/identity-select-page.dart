import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:dvote_crypto/main/encryption.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';
import 'package:vocdoni/views/onboarding/onboarding-account-naming.dart';
import 'package:vocdoni/views/onboarding/pin-transfer.dart';
import '../app-config.dart';
import '../lib/globals.dart';
import 'onboarding/onboarding-backup-input.dart';

class IdentitySelectPage extends StatefulWidget {
  @override
  _IdentitySelectPageState createState() => _IdentitySelectPageState();
}

class _IdentitySelectPageState extends State<IdentitySelectPage> {
  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("AccountSelect");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          body: Builder(
              builder: (context) => ListView(
                    // use this context within Scaffold for Toast's to work
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                          Section(
                              text: getText(context, "main.selectAnIdentity"))
                        ] +
                        buildExistingIdentities(
                            context, Globals.accountPool.value) +
                        [
                          SizedBox(height: 50),
                          Section(
                              text: getText(context, "action.addAnIdentity")),
                          ListItem(
                              mainText:
                                  getText(context, "action.createANewIdentity"),
                              icon: FeatherIcons.plusCircle,
                              onTap: () => createNew(context)),
                          ListItem(
                              mainText: getText(
                                  context, "main.restoreAnExistingIdentity"),
                              icon: FeatherIcons.rotateCw,
                              onTap: () => restorePreviousIdentity(context)),
                          SizedBox(height: 50),
                        ],
                  )),
        ));
  }

  List<Widget> buildExistingIdentities(
      BuildContext ctx, List<AccountModel> accounts) {
    List<Widget> list = new List<Widget>();
    if (accounts == null) return list;

    for (var i = 0; i < accounts.length; i++) {
      if (!accounts[i].identity.hasValue) continue;

      list.add(ListItem(
        mainText: accounts[i].identity.value.alias,
        icon: FeatherIcons.user,
        onTap: () => onAccountSelected(ctx, accounts[i], i),
      ));
    }
    return list;
  }

  /////////////////////////////////////////////////////////////////////////////
  // GLOBAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  Future<bool> handleWillPop() async {
    if (!Navigator.canPop(context)) {
      // dispose any resource in use
    }
    return true;
  }

  /////////////////////////////////////////////////////////////////////////////
  // LOCAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  onAccountSelected(
      BuildContext ctx, AccountModel account, int accountIdx) async {
    if (!account.identity.hasValue) return;
    final accountHasPin = account.identity.value.version != null &&
        account.identity.value.version.length > 0;

    if (accountHasPin) {
      var privKey = await Navigator.push(
          ctx,
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PinPromptModal(account)));

      if (privKey == null)
        return;
      else if (privKey is InvalidPatternError) {
        showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
            context: ctx, purpose: Purpose.DANGER);
        return;
      }
      privKey = "";
    } else {
      logger.log("Account has no pin.");
      final oldLockPattern = await Navigator.push(
          ctx,
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PatternPromptModal(account)));

      if (oldLockPattern == null) {
        return;
      } else if (oldLockPattern is InvalidPatternError) {
        logger.log("Pattern is incorrect.");
        showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
            purpose: Purpose.DANGER, context: ctx);
        return;
      }
      logger.log("Key decrypted correctly");

      final newLockPattern = await Navigator.push(
        ctx,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => PinTransferPage(
            account.identity.value.alias,
          ),
        ),
      );

      if (newLockPattern == null) {
        return;
      } else if (newLockPattern is InvalidPatternError) {
        showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
            purpose: Purpose.DANGER, context: context);
        return;
      }
      final loading = showLoading(getText(context, "main.generatingIdentity"),
          context: ctx);

      // Generate new identity from old one, with pin authentication

      final oldEncryptedMnemonic =
          account.identity.value.keys[0].encryptedMnemonic;
      final oldEncryptedRootPrivateKey =
          account.identity.value.keys[0].encryptedRootPrivateKey;

      final mnemonic = await Symmetric.decryptStringAsync(
          oldEncryptedMnemonic, oldLockPattern);
      final privateKey = await Symmetric.decryptStringAsync(
          oldEncryptedRootPrivateKey, oldLockPattern);

      final encryptedMenmonic =
          await Symmetric.encryptStringAsync(mnemonic, newLockPattern);
      final encryptedRootPrivateKey =
          await Symmetric.encryptStringAsync(privateKey, newLockPattern);

      account.identity.value.keys[0].encryptedMnemonic = encryptedMenmonic;
      account.identity.value.keys[0].encryptedRootPrivateKey =
          encryptedRootPrivateKey;
      account.identity.value.version =
          AppConfig.packageInfo?.buildNumber ?? IDENTITY_VERSION;
      loading.close();
    }
    Globals.appState.selectAccount(accountIdx);
    Globals.accountPool.writeToStorage();
    if (Globals.appState.currentAccount?.identity?.value?.backedUp == true) {
      // Replace all routes with /home on top
      Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingBackupInput(),
          ),
          (Route _) => false);
    }
  }

  createNew(BuildContext ctx) {
    final route = MaterialPageRoute(
      builder: (context) => OnboardingAccountNamingPage(),
    );
    Navigator.push(context, route);
  }

  restorePreviousIdentity(BuildContext ctx) {
    Navigator.pushNamed(ctx, "/identity/restore");
  }
}
