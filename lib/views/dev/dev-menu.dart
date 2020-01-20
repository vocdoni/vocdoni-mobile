import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/lib/dev/populate.dart';
import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/widgets/toast.dart';

class DevMenu extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: "Post",
      ),
      body: Builder(
          builder: (BuildContext context) => ListView(
                children: <Widget>[
                  ListItem(
                      mainText: "Update the identity keys",
                      onTap: () {
                        setCustomIdentityKeys(context);
                      }),
                  ListItem(
                      mainText: "Add fake organizations",
                      onTap: () {
                        populateSampleData();
                      }),
                  ListItem(
                    mainText: "ListItem variations (UI)",
                    onTap: () {
                      Navigator.pushNamed(ctx, "/dev/ui-listItem");
                    },
                  ),
                  ListItem(
                    mainText: "Cards variations (UI)",
                    onTap: () {
                      Navigator.pushNamed(ctx, "/dev/ui-card");
                    },
                  ),
                  ListItem(
                    mainText: "Avatar color generation (UI)",
                    onTap: () {
                      Navigator.pushNamed(ctx, "/dev/ui-avatar-colors");
                    },
                  ),
                  ListItem(
                    mainText: "Handle deeplink (Esqueixada)",
                    onTap: () {
                      String link =
                          'vocdoni://vocdoni.app/entity?entityId=0x8dfbc9c552338427b13ae755758bb5fd7df4fce0f98ceff56c791e5b74fcffba&entryPoints[]=https://gwdev1.vocdoni.net/web3&entryPoints[]=https://gwdev2.vocdoni.net/web3';
                      handleIncomingLink(Uri.parse(link), ctx);
                    },
                  ),
                  ListItem(
                    mainText: "Handle deeplink (VocdoniTest)",
                    onTap: () {
                      String link =
                          'vocdoni://vocdoni.app/entity?entityId=0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85&entryPoints[]=https://gwdev1.vocdoni.net/web3&entryPoints[]=https://gwdev2.vocdoni.net/web3';
                      handleIncomingLink(Uri.parse(link), ctx);
                    },
                  ),
                  ListItem(
                    mainText: "Handle deeplink (A new world)",
                    onTap: () {
                      String link =
                          'vocdoni://vocdoni.app/entity?entityId=0xf6a97d2ec8bb9fabde28b9e377edbd31e92bef3b44040f0752e28896f4baed90&entryPoints[]=https://gwdev1.vocdoni.net/web3&entryPoints[]=https://gwdev2.vocdoni.net/web3';
                      handleIncomingLink(Uri.parse(link), ctx);
                    },
                  ),
                  ListItem(
                    mainText: "Analytics",
                    onTap: () {
                      Navigator.pushNamed(ctx, "/dev/analytics-tests");
                    },
                  ),
                  ListItem(
                    mainText: "Pager test",
                    onTap: () {
                      Navigator.pushNamed(ctx, "/dev/pager");
                    },
                  ),
                ],
              )),
    );
  }

  setCustomIdentityKeys(context) async {
    // CHANGEME: Set the new Mnemonic key here
    const NEW_MNEMONIC =
        "wealth matrix piano veteran disease digital hard arrow blossom eight simple solid";

    final currentAccount = globalAppState.currentAccount;
    if (!(currentAccount is AccountModel))
      throw Exception("No account is currently selected");
    else if (!currentAccount.identity.hasValue ||
        currentAccount.identity.value.keys.length == 0)
      throw Exception("No account is currently selected");

    var patternLockKey = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaternPromptModal(currentAccount)));

    if (patternLockKey == null || patternLockKey is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: context, purpose: Purpose.DANGER);
      return;
    }

    final privateKey = await mnemonicToPrivateKey(NEW_MNEMONIC);
    final publicKey = await mnemonicToPublicKey(NEW_MNEMONIC);
    final address = await mnemonicToAddress(NEW_MNEMONIC);

    final encryptedMenmonic = await encryptString(NEW_MNEMONIC, patternLockKey);
    final encryptedPrivateKey = await encryptString(privateKey, patternLockKey);

    final updatedIdentity = currentAccount.identity.value;
    updatedIdentity.meta[META_ACCOUNT_ID] = publicKey;

    dvote.Key k = dvote.Key();
    k.type = Key_Type.SECP256K1;
    k.encryptedMnemonic = encryptedMenmonic;
    k.encryptedPrivateKey = encryptedPrivateKey;
    k.publicKey = publicKey;
    k.address = address;

    updatedIdentity.keys[0] = k;
    currentAccount.identity.setValue(updatedIdentity);

    globalAccountPool.writeToStorage();
  }
}
