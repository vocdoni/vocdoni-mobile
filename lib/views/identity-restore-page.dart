import 'package:dvote/dvote.dart';
import 'package:dvote_common/dvote_common.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/loading-spinner.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/view-modals/pattern-create-modal.dart';
import 'package:vocdoni/lib/i18n.dart';

class IdentityRestorePage extends StatefulWidget {
  @override
  _IdentityRestorePageState createState() => _IdentityRestorePageState();
}

class _IdentityRestorePageState extends State<IdentityRestorePage> {
  final nameController = TextEditingController();
  final mnemonicController = TextEditingController();
  final nameNode = FocusNode();
  final mnemonicNode = FocusNode();
  bool restoring = false;

  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("IdentityRestorePage");

    Future.delayed(Duration(milliseconds: 100)).then((_) {
      FocusScope.of(context).requestFocus(nameNode);
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    mnemonicController.dispose();
    super.dispose();
  }

  onSubmit(context) async {
    final alias = nameController.text.trim();
    final mnemonic = mnemonicController.text.trim();

    String err;
    if (alias.length == 0)
      err = getText(context, "Enter a name for the account");
    else if (mnemonic.length == 0)
      err = getText(context, "Enter the mnemonic words to recover");
    else if (!RegExp(r"^([a-zA-Z]+ )+[a-zA-Z]+$").hasMatch(mnemonic))
      err = getText(context, "The mnemonic words you entered is not valid");
    if (err is String) {
      showMessage(err, context: context, purpose: Purpose.WARNING);
      return;
    }

    final words = mnemonic.replaceAll(RegExp(r'[ ]+'), " ").split(" ");
    switch (words.length) {
      case 12:
      case 15:
      case 18:
      case 21:
      case 24:
        break;
      default:
        showMessage(
            getText(context, "The number of words you entered is not valid"),
            context: context,
            purpose: Purpose.WARNING);
        return;
    }

    try {
      final w =
          await EthereumNativeWallet.fromMnemonic(mnemonic).privateKeyAsync;
      if (!(w is String)) throw Exception();
    } catch (err) {
      showMessage(getText(context, "The words you entered are not valid"),
          context: context, purpose: Purpose.WARNING);
      return;
    }

    final patternEncryptionKey = await Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => PatternCreateModal(canGoBack: true)),
    );

    if (patternEncryptionKey == null) {
      return;
    }

    try {
      setState(() => restoring = true);

      final newAccount = await AccountModel.fromMnemonic(
          mnemonic, alias, patternEncryptionKey);
      await globalAccountPool.addAccount(newAccount);

      int newIndex = -1;
      for (int i = 0; i < globalAccountPool.value.length; i++) {
        // TODO: Compare by identityId instead of rootPublicKey
        if (!globalAccountPool.value[i].identity.hasValue)
          continue;
        else if (globalAccountPool
                .value[i].identity.value.keys[0].rootPublicKey !=
            newAccount.identity.value.keys[0].rootPublicKey) continue;
        newIndex = i;
        break;
      }
      if (newIndex < 0)
        throw Exception("The new account can't be found on the pool");

      globalAppState.selectAccount(newIndex);
      // globalAppState.currentAccount?.cleanEphemeral();
      // globalAccountPool.writeToStorage();   not needed => addAccount() does it

      showHomePage(context);
    } catch (err) {
      String text;
      setState(() => restoring = false);

      if (err.toString() ==
          "Exception: An account with this name already exists") {
        text = getText(context, "An account with this name already exists");
      } else {
        text =
            getText(context, "An error occurred while restoring the identity");
      }

      showAlert(text, title: getText(context, "Error"), context: context);
    }
  }

  renderLoading() {
    return Center(
      child: Align(
        alignment: Alignment(0, -0.1),
        child: Container(
          constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
          color: Color(0x00ff0000),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(getText(context, "Restoring identity..."),
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              LoadingSpinner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget renderOkButton(BuildContext context) {
    return BaseButton(
      maxWidth: double.infinity,
      purpose: Purpose.HIGHLIGHT,
      text: getText(context, "Restore identity"),
      onTap: () => onSubmit(context),
    ).withPadding(16);
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(context, "Identity"),
      ),
      body: Builder(
        builder: (context) {
          if (restoring) return renderLoading();

          return ListView(children: <Widget>[
            Text(
              getText(context,
                  "To restore your user keys enter the mnemonic words you saved during the back up."),
              style: TextStyle(color: Colors.black45),
            ).withPadding(16),
            TextField(
              controller: nameController,
              focusNode: nameNode,
              style: TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                // border: InputBorder.none,
                hintText: getText(context, "What's your name?"),
              ),
            ).withHPadding(16),
            TextField(
              controller: mnemonicController,
              focusNode: mnemonicNode,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                // border: InputBorder.none,
                hintText: getText(context, 'Mnemonic words'),
              ),
            ).withPadding(16).withTopPadding(8),
            SizedBox(height: 16),
            renderOkButton(context),
          ]);
        },
      ),
    );
  }

  /////////////////////////////////////////////////////////////////////////////
  // LOCAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  showHomePage(BuildContext ctx) {
    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }
}
