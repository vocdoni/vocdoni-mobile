import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/widgets/toast.dart';
import '../lib/singletons.dart';
import 'package:dvote/dvote.dart';

class IdentitySelectPage extends StatefulWidget {
  @override
  _IdentitySelectPageState createState() => _IdentitySelectPageState();
}

class _IdentitySelectPageState extends State<IdentitySelectPage> {
  @override
  void initState() {
    super.initState();
    analytics.trackPage(pageId: "IdentitySelectPage");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                return listContent(ctx, appState.data, identities.data);
              });
        });
  }

  Widget listContent(
      BuildContext ctx, AppState appState, List<Identity> identities) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Section(text: "Select an identity"),
              buildExistingIdentities(ctx, identities),
              ListItem(
                  mainText: "Create a new one", onTap: () => createNew(ctx)),
            ],
          ),
        ));
  }

  buildExistingIdentities(BuildContext ctx, identities) {
    List<Widget> list = new List<Widget>();
    if (identities == null) return Column(children: list);

    for (var i = 0; i < identities.length; i++) {
      list.add(ListItem(
        mainText: identities[i].alias,
        onTap: () => onIdentitySelected(ctx, i),
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

  onIdentitySelected(BuildContext ctx, int idx) async {
    final identity = identitiesBloc.value[idx];

    var result = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) =>
                PaternPromptModal(identity.keys[0].encryptedPrivateKey)));
    if (result == null || result is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
      return;
    }
    appStateBloc.selectIdentity(idx);
    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }

  createNew(BuildContext ctx) {
    Navigator.pushNamed(ctx, "/identity/create");
  }
}
