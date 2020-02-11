import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/widgets/toast.dart';
import '../lib/singletons.dart';

class IdentitySelectPage extends StatefulWidget {
  @override
  _IdentitySelectPageState createState() => _IdentitySelectPageState();
}

class _IdentitySelectPageState extends State<IdentitySelectPage> {
  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("IdentitySelectPage");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          body: Builder(
              builder: (context) => Column(
                    // use this context within Scaffold for Toast's to work
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Section(text: "Select an identity"),
                      buildExistingIdentities(context, globalAccountPool.value),
                      ListItem(
                          mainText: "Create a new one",
                          onTap: () => createNew(context)),
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
    var patternEncryptionKey = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PatternPromptModal(account)));

    if (patternEncryptionKey == null ||
        patternEncryptionKey is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
      return;
    }
    globalAppState.selectAccount(accountIdx);

    account.refresh(false, patternEncryptionKey); // detached async

    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }

  createNew(BuildContext ctx) {
    Navigator.pushNamed(ctx, "/identity/create");
  }
}
