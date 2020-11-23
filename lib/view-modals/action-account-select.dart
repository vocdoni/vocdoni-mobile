import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/account.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/i18n.dart';
import '../lib/globals.dart';

class LinkAccountSelect extends StatefulWidget {
  @override
  _LinkAccountSelectState createState() => _LinkAccountSelectState();
}

class _LinkAccountSelectState extends State<LinkAccountSelect> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          appBar: TopNavigation(
            title: getText(context, "main.selectAnIdentity"),
            onBackButton: () => Navigator.pop(context, false),
          ),
          body: Builder(
              builder: (context) => ListView(
                    children: <Widget>[
                      buildExistingIdentities(
                          context, Globals.accountPool.value),
                    ],
                  )),
        ));
  }

  buildExistingIdentities(BuildContext ctx, List<AccountModel> accounts) {
    List<Widget> list = new List<Widget>();
    if (accounts == null) return Column(children: list);

    for (var i = 0; i < accounts.length; i++) {
      if (!accounts[i].identity.hasValue) continue;

      list.add(ListItem(
        mainText: accounts[i].identity.value.alias,
        icon: FeatherIcons.user,
        onTap: () => onAccountSelected(ctx, accounts[i], i),
      ));
    }
    return Column(children: list);
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
    Globals.appState.selectAccount(accountIdx);
    if (Globals.appState.currentAccount is! AccountModel)
      throw Exception("No account available");

    Globals.appState.currentAccount.cleanEphemeral();
    Globals.appState.currentAccount.refresh(force: false); // detached async

    Navigator.pop(ctx, true);
  }
}
