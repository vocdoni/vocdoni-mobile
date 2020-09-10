// import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/loading-spinner.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/gestures.dart';
import "package:flutter/material.dart";
import 'package:url_launcher/url_launcher.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/view-modals/pattern-create-modal.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote_common/widgets/alerts.dart';
// import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/extensions.dart';

class IdentityCreatePage extends StatefulWidget {
  final bool showRestoreIdentityAction;
  final bool cangoBack;

  IdentityCreatePage(
      {this.showRestoreIdentityAction = false, this.cangoBack = false});

  @override
  _IdentityCreateScreen createState() => _IdentityCreateScreen();
}

class _IdentityCreateScreen extends State<IdentityCreatePage> {
  bool generating = false;
  bool termsAccepted = false;
  TextEditingController nameTextFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("IdentityCreatePage");
  }

  @override
  Widget build(context) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          appBar: widget.cangoBack
              ? TopNavigation(
                  title: getText(context, "main.identity"),
                )
              : null,
          body: Builder(builder: (BuildContext context) {
            return Center(
              child: Align(
                alignment: Alignment(0, 0),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 320, maxHeight: 400),
                  color: Color(0x00ff0000),
                  child: generating ? buildGenerating() : buildWelcome(context),
                ),
              ),
            );
          }),
        ));
  }

  buildWelcome(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
            child: Text(getText(context, "main.welcome"),
                style: new TextStyle(fontSize: 30, color: Color(0xff888888)))),
        SizedBox(height: 50),
        Center(
          child: TextField(
              controller: nameTextFieldController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  hintStyle: TextStyle(color: Colors.black38),
                  hintText: getText(context, "main.whatsYourName")),
              onSubmitted: (alias) => createIdentity(context, alias)),
        ),
        SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Checkbox(
                value: termsAccepted,
                onChanged: (value) {
                  this.setState(() => {this.termsAccepted = value});
                },
                activeColor: Theme.of(context).primaryColor),
            Expanded(
                child: RichText(
              // maxLines: 2,
              text: TextSpan(text: '', children: [
                TextSpan(
                    text: getText(context, "main.iAccept") + " ",
                    style: TextStyle(
                        color:
                            termsAccepted ? Colors.black54 : Colors.black38)),
                TextSpan(
                  text: getText(context, "main.thePrivacyPolicy"),
                  style: TextStyle(
                      color: termsAccepted ? Colors.black54 : Colors.black38,
                      decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => launch("https://vocdoni.io/privacy-policy/)"),
                ),
                TextSpan(
                    text: " " + getText(context, "main.and") + " ",
                    style: TextStyle(
                        color:
                            termsAccepted ? Colors.black54 : Colors.black38)),
                TextSpan(
                  text: getText(context, "main.theTermsOfService"),
                  style: TextStyle(
                      color: termsAccepted ? Colors.black54 : Colors.black38,
                      decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => launch("https://vocdoni.io/terms-of-service/"),
                ),
              ]),
            )),
          ],
        ),
        SizedBox(height: 20),
        BaseButton(
          maxWidth: double.infinity,
          purpose: Purpose.HIGHLIGHT,
          text: getText(context, "main.continue"),
          isDisabled: !termsAccepted,
          onTap: () => createIdentity(context, nameTextFieldController.text),
        ),
        // Only when showRestoreIdentityAction is set
        BaseButton(
          style: BaseButtonStyle.OUTLINE,
          maxWidth: double.infinity,
          purpose: Purpose.GUIDE,
          text: getText(context, "main.iHaveAnAccount"),
          onTap: () => showRestoreIdentity(context),
        ).withTopPadding(10).when(widget.showRestoreIdentityAction),
      ],
    );
  }

  buildGenerating() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(getText(context, "main.generatingIdentity"),
            style: TextStyle(fontSize: 18)),
        SizedBox(height: 20),
        LoadingSpinner(),
      ],
    );
  }

  createIdentity(BuildContext context, String alias) async {
    if (!termsAccepted) return;

    alias = alias.trim();
    if (!(alias is String) || alias == "")
      return;
    else if (alias.length < 2) {
      showMessage(getText(context, "main.theNameIsTooShort"),
          context: context, purpose: Purpose.WARNING);
      return;
    } else if (RegExp(r"[<>/\\|%=^*`´]").hasMatch(alias)) {
      showMessage(getText(context, "main.theNameContainsInvalidSymbols"),
          context: context, purpose: Purpose.WARNING);
      return;
    }

    final repeated = globalAccountPool.value.any((item) {
      if (!item.identity.hasValue) return false;
      return item.identity.value.alias == alias;
    });
    if (repeated) {
      showMessage(
          getText(context, "main.youAlreadyHaveAnAccountWithThisName"),
          context: context,
          purpose: Purpose.WARNING);
      return;
    }

    final String patternEncryptionKey = await Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => PatternCreateModal(canGoBack: true)),
    );

    if (patternEncryptionKey == null) {
      return;
    }
    // showSuccessMessage("Pattern has been set!", context: context);

    // READY, now create the identity

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
      // globalAppState.currentAccount?.cleanEphemeral();
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
        text = getText(context, "main.anAccountWithThisNameAlreadyExists");
      } else {
        text =
            getText(context, "main.anErrorOccurredWhileGeneratingTheIdentity");
      }

      showAlert(text, title: getText(context, "main.error"), context: context);
    }
  }

  void showRestoreIdentity(BuildContext context) {
    Navigator.pushNamed(context, "/identity/restore");
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
