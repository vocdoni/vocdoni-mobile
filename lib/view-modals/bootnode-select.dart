import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:eventual/eventual-notifier.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/views/startup-page.dart';

EventualNotifier<List<String>> availableBootnodes = EventualNotifier([
  "https://bootnodes.vocdoni.net/gateways.json",
  "https://bootnodes.vocdoni.net/gateways.stg.json",
  "https://bootnodes.vocdoni.net/gateways.dev.json",
]);

class BootnodeSelectPage extends StatelessWidget {
  @override
  Widget build(ctx) {
    if (!availableBootnodes.value.contains(AppConfig.bootnodesUri)) {
      List<String> uriList = availableBootnodes.value;
      uriList.add(AppConfig.bootnodesUri);
      availableBootnodes.setValue(uriList);
    }
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "title.bootnodeUri"),
      ),
      body: EventualBuilder(
        notifier: availableBootnodes,
        builder: (BuildContext context, _, __) => Column(
          children: [
            Expanded(
                child: ListView(
              children: availableBootnodes.value
                  .map((uri) => buildBootnodeItem(ctx, uri))
                  .toList(),
            )),
            FloatingActionButton(
              onPressed: () => onAddUri(ctx),
              backgroundColor: colorBlue,
              child: Icon(FeatherIcons.plusCircle),
              elevation: 5.0,
              tooltip: getText(ctx, "main.addBootnodeUri"),
            ).withBottomPadding(15),
          ],
        ),
      ),
    );
  }

  Widget buildBootnodeItem(BuildContext context, String uri) {
    return ListItem(
        mainText: uri,
        mainTextMultiline: 3,
        rightIcon: AppConfig.bootnodesUri == uri
            ? FeatherIcons.check
            : FeatherIcons.target,
        onTap: () {
          AppConfig.setBootnodesUriOverride(uri);
          Globals.appState.bootnodeInfo.setValue(null);
          // AppNetworking.setGateways(null, "");
          Globals.appState.writeToStorage();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => StartupPage(),
                fullscreenDialog: true,
              ),
              (Route _) => false);
        });
  }

  onAddUri(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        String newUri;
        return AlertDialog(
          title: Text(getText(context, "main.addBootnodeUri")),
          content: TextField(
            onChanged: (value) => newUri = value,
            style: TextStyle(fontSize: 18),
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
                // hintText: getText(context, "main.addBootnodeUri"),
                ),
          ),
          actions: [
            FlatButton(
              child: Text(getText(context, "main.cancel")),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text(getText(context, "main.ok")),
              onPressed: () {
                List<String> uriList = availableBootnodes.value;
                uriList.add(newUri);
                availableBootnodes.setValue(uriList);
                Navigator.of(context).pop(true);
              },
            )
          ],
        );
      },
    );
  }
}
