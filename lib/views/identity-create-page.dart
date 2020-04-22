import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/loading-spinner.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/view-modals/pattern-create-modal.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:vocdoni/lib/extensions.dart';
import '../lang/index.dart';

class IdentityCreatePage extends StatefulWidget {
  @override
  _IdentityCreateScreen createState() => _IdentityCreateScreen();
}

class _IdentityCreateScreen extends State<IdentityCreatePage> {
  bool generating = false;

  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("IdentityCreatePage");
  }

  @override
  Widget build(context) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(body: Builder(builder: (BuildContext context) {
          return Center(
            child: Align(
              alignment: Alignment(0, -0.1),
              child: Container(
                constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
                color: Color(0x00ff0000),
                child: generating ? buildGenerating() : buildWelcome(context),
              ),
            ),
          );
        })));
  }

  buildWelcome(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
            child: Text("Welcome!",
                style: new TextStyle(fontSize: 30, color: Color(0xff888888)))),
        SizedBox(height: 100),
        Center(
          child: TextField(
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(hintText: "What's your name?"),
              onSubmitted: (alias) => createIdentity(context, alias)),
        ),
      ],
    );
  }

  buildGenerating() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text("Generating identity...", style: TextStyle(fontSize: 18)),
        SizedBox(height: 20),
        LoadingSpinner(),
      ],
    );
  }

  createIdentity(BuildContext context, String alias) async {
    if (!(alias is String) || alias == "")
      return;
    else if (alias.length < 2) {
      showAlert(Lang.of(context).get("The identity name is too short"),
          title: Lang.of(context).get("Error"), context: context);
      return;
    }
    String patternEncryptionKey = await Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => PatternCreateModal(canGoBack: true)),
    );

    if (patternEncryptionKey == null) {
      return; // showMessage("Pattern was cancelled", context: context);
    }
    // showSuccessMessage("Pattern has been set!", context: context);

    try {
      setState(() {
        generating = true;
      });

      final newAccount =
          await AccountModel.makeNew(alias, patternEncryptionKey);
      await globalAccountPool.addAccount(newAccount);

      final newIndex = globalAccountPool.value.indexWhere((account) =>
          account.identity.hasValue &&
          account.identity.value.identityId ==
              newAccount.identity.value.identityId);
      if (newIndex < 0)
        throw Exception("The new account can't be found on the pool");

      globalAppState.selectAccount(newIndex);
      // globalAccountPool.writeToStorage();   not needed => addAccount() does it

      setState(() {
        generating = false;
      });

      showHomePage(context);
    } on Exception catch (err) {
      String text;
      setState(() {
        generating = false;
      });

      if (err.toString() ==
          "Exception: An account with this name already exists") {
        text = Lang.of(context).get("An account with this name already exists");
      } else {
        text = Lang.of(context)
            .get("An error occurred while generating the identity");
      }

      showAlert(text, title: Lang.of(context).get("Error"), context: context);
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // GLOBAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  Future<bool> handleWillPop() async {
    if (generating)
      return false;
    else if (!Navigator.canPop(context)) {
      // dispose any resource in use
    }
    return true;
  }

  /////////////////////////////////////////////////////////////////////////////
  // LOCAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  showHomePage(BuildContext ctx) {
    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }
}
