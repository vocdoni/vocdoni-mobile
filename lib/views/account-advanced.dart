import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/view-modals/bootnode-select.dart';
import 'package:vocdoni/view-modals/ens-domain-select.dart';
import 'package:vocdoni/view-modals/language-select.dart';
import 'package:vocdoni/view-modals/network-select.dart';
import 'package:vocdoni/views/app-logs.dart';

class AccountAdvanced extends StatefulWidget {
  AccountAdvanced();

  @override
  _AccountAdvancedState createState() => _AccountAdvancedState();
}

class _AccountAdvancedState extends State<AccountAdvanced> {
  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("AccountAdvanced");
  }

  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "main.settings"),
      ),
      body: Builder(
          builder: (BuildContext context) => ListView(
                children: <Widget>[
                  ListItem(
                    mainText: getText(context, "main.selectLanguage"),
                    onTap: () => showLanguageSelector(context),
                    icon: FeatherIcons.globe,
                  ),
                  Section(text: getText(context, "main.advanced")),
                  ListItem(
                    mainText: getText(context, "main.setBootnodesUrl"),
                    onTap: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => BootnodeSelectPage()),
                      );
                    },
                    icon: FeatherIcons.radio,
                  ),
                  ListItem(
                    mainText: getText(context, "main.setNetworkId"),
                    onTap: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => NetworkSelectPage()),
                      );
                    },
                    icon: FeatherIcons.radio,
                  ),
                  ListItem(
                    mainText: getText(context, "main.setEnsDomainSuffix"),
                    onTap: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => EnsDomainSelectPage()),
                      );
                    },
                    icon: FeatherIcons.radio,
                  ),
                  ListItem(
                    mainText: getText(context, "action.viewAppLogs"),
                    // rightIcon: null,
                    icon: FeatherIcons.book,
                    onTap: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => AppLogs()),
                      );
                    },
                  ),
                  ListItem(
                    mainText: getText(context, "action.removeAccount"),
                    purpose: Purpose.DANGER,
                    rightIcon: null,
                    icon: FeatherIcons.trash2,
                    onTap: () {
                      onRemoveAccount(context);
                    },
                  ),
                ],
              )),
    );
  }

  showLanguageSelector(BuildContext ctx) async {
    bool success = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true, builder: (context) => LanguageSelect()));

    if (success == null) return;
    await Future.delayed(Duration(milliseconds: 200));
    showMessage(getText(ctx, "main.theLanguageHasBeenDefined"),
        context: ctx, purpose: Purpose.GOOD);
  }

  onRemoveAccount(BuildContext ctx) async {
    final confirm = await showPrompt(
        getText(ctx,
            "main.thisActionWillPermanentlyEraseYourAccountFromThisDevice"),
        context: ctx,
        title: getText(ctx, "main.areYouSureYouWantToDeleteName").replaceFirst(
            "{{NAME}}", Globals.appState.currentAccount.identity.value.alias),
        okButton: getText(ctx, "main.ok"),
        cancelButton: getText(ctx, "main.cancel"));
    if (confirm) {
      ScaffoldFeatureController<SnackBar, SnackBarClosedReason> indicator =
          showLoading(getText(ctx, "main.removingAccountData"), context: ctx);
      // await Future.delayed(Duration(seconds: 5));
      try {
        await Globals.accountPool.removeCurrentAccount();
      } catch (err) {
        logger.log("Error removing account: $err");
        indicator.close();
        showMessage(getText(context, "error.couldNotRemoveAccount"),
            purpose: Purpose.DANGER, context: context);
        return;
      }
      indicator.close();
      Navigator.pushNamedAndRemoveUntil(
          ctx, "/identity/select", (Route _) => false);
    }
  }
}
