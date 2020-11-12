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
import 'package:vocdoni/views/startup-page.dart';

EventualNotifier<List<String>> availableBootnodes = EventualNotifier([
  "https://bootnodes.vocdoni.net/gateways.json",
  "https://bootnodes.vocdoni.net/gateways.stg.json",
  "https://bootnodes.vocdoni.net/gateways.dev.json",
]);

class BootnodeSelectPage extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "title.bootnodeUrl"),
      ),
      body: EventualBuilder(
        notifier: availableBootnodes,
        builder: (BuildContext context, _, __) {
          List<Widget> urlList = availableBootnodes.value
              .map((uri) => buildBootnodeItem(ctx, uri))
              .toList();
          if (!availableBootnodes.value.contains(AppConfig.bootnodesUrl)) {
            urlList.add(buildBootnodeItem(ctx, AppConfig.bootnodesUrl));
          }
          return Column(
            children: [
              Expanded(
                  child: ListView(
                children: urlList,
              )),
              FloatingActionButton(
                onPressed: () => onAddUri(ctx),
                backgroundColor: colorBlue,
                child: Icon(FeatherIcons.plusCircle),
                elevation: 5.0,
                tooltip: getText(ctx, "main.addbootnodeUrl"),
              ).withBottomPadding(15),
            ],
          );
        },
      ),
    );
  }

  Widget buildBootnodeItem(BuildContext context, String uri) {
    return ListItem(
        mainText: uri,
        mainTextMultiline: 3,
        rightIcon: AppConfig.bootnodesUrl == uri
            ? FeatherIcons.check
            : FeatherIcons.target,
        onTap: () {
          AppConfig.setBootnodesUrlOverride(uri);
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
          title: Text(getText(context, "main.addbootnodeUrl")),
          content: TextField(
            onChanged: (value) => newUri = value,
            style: TextStyle(fontSize: 18),
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(),
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
