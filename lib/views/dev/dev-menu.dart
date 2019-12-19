import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/app-links.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/util/dev/populate.dart';
import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
// import 'package:vocdoni/models/account.dart';
import 'package:vocdoni/modals/pattern-prompt-modal.dart';
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
    const NEW_MNEMONIC =
        "upper planet shove rib metal gown ramp fly liberty gun slender spread";

    var patternLockKey = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaternPromptModal(
                account.identity.keys[0].encryptedPrivateKey)));

    if (patternLockKey == null || patternLockKey is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: context, purpose: Purpose.DANGER);
      return;
    }

    // final privateKey = await decryptString(
    //     account.identity.keys[0].encryptedPrivateKey, patternLockKey);

    final currentIdentity = identitiesBloc.getCurrentIdentity();

    final privateKey = await privateKeyFromMnemonic(NEW_MNEMONIC);
    final publicKey = await publicKeyFromMnemonic(NEW_MNEMONIC);
    final address = await addressFromMnemonic(NEW_MNEMONIC);
    
    final encryptedMenmonic = await encryptString(NEW_MNEMONIC, patternLockKey);
    final encryptedPrivateKey = await encryptString(privateKey, patternLockKey);

    currentIdentity.identityId = publicKey;

    dvote.Key k = dvote.Key();
    k.type = Key_Type.SECP256K1;
    k.encryptedMnemonic = encryptedMenmonic;
    k.encryptedPrivateKey = encryptedPrivateKey;
    k.publicKey = publicKey;
    k.address = address;

    currentIdentity.keys[0] = k;
    identitiesBloc.value[appStateBloc.value.selectedIdentity] = currentIdentity;

    identitiesBloc.set(identitiesBloc.value);
    identitiesBloc.persist();
  }
}
