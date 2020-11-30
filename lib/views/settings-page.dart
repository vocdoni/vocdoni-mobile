import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/view-modals/bootnode-select.dart';
import 'package:vocdoni/view-modals/language-select.dart';

class SettingsMenu extends StatefulWidget {
  SettingsMenu();

  @override
  _SettingsMenuState createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("SettingsPage");
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
                  ListItem(
                    mainText: getText(context, "main.setbootnodesUrl"),
                    onTap: () {
                      Navigator.push(
                          ctx,
                          MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => BootnodeSelectPage()));
                    },
                    icon: FeatherIcons.radio,
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
}
