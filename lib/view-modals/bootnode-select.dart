import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/dvote_common.dart';
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
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/startup.dart';
import 'package:vocdoni/views/startup-page.dart';

EventualNotifier<List<String>> availableBootnodes = EventualNotifier([
  "https://bootnodes.vocdoni.net/gateways.json",
  "https://bootnodes.vocdoni.net/gateways.stg.json",
  "https://bootnodes.vocdoni.net/gateways.dev.json",
]);

class BootnodeSelectPage extends StatefulWidget {
  @override
  _BootnodeSelectPageState createState() => _BootnodeSelectPageState();
}

class _BootnodeSelectPageState extends State<BootnodeSelectPage> {
  bool isLoadingBootnode;
  String currentUrl;

  @override
  void initState() {
    isLoadingBootnode = false;
    currentUrl = AppConfig.bootnodesUrl;
    super.initState();
  }

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
              .map((url) => buildBootnodeItem(ctx, url))
              .toList();
          if (!availableBootnodes.value.contains(currentUrl)) {
            urlList.add(buildBootnodeItem(ctx, currentUrl));
          }
          return Column(
            children: [
              Expanded(
                  child: ListView(
                children: urlList,
              )),
              FloatingActionButton(
                onPressed: () => onAddUrl(ctx),
                backgroundColor: colorBlue,
                child: Icon(FeatherIcons.plusCircle),
                elevation: 5.0,
                tooltip: getText(ctx, "action.addbootnodeUrl"),
              ).withBottomPadding(15),
            ],
          );
        },
      ),
    );
  }

  Widget buildBootnodeItem(BuildContext context, String url) {
    return ListItem(
        mainText: url,
        mainTextMultiline: 3,
        isSpinning: currentUrl == url && isLoadingBootnode,
        rightIcon: currentUrl == url
            ? Globals.appState.bootnodeInfo.hasError
                ? FeatherIcons.x
                : FeatherIcons.check
            : FeatherIcons.target,
        onTap: buildOnTap(context, url));
  }

  Function() buildOnTap(BuildContext context, String url) {
    return () async {
      setState(() {
        currentUrl = url;
        isLoadingBootnode = true;
      });
      try {
        await AppConfig.setBootnodesUrlOverride(url);
        await Globals.appState.refresh();
      } catch (err) {
        logger.log("$err");
        showAlert(
            getText(context, "main.bootnodeUrl") +
                " " +
                url +
                " " +
                getText(context, "main.mayBeInvalid").toLowerCase() +
                " " +
                getText(context, "main.orIncompatibleWithTheNETWORKNetwork")
                    .replaceAll("{{NETWORK}}", AppConfig.networkId)
                    .toLowerCase(),
            title: getText(context, "main.unableToFetchBootnodeGateways"),
            context: context);
        setState(() {
          isLoadingBootnode = false;
        });
        return;
      }
      setState(() {
        isLoadingBootnode = false;
      });
      Globals.appState.bootnodeInfo.setValue(null);
      Globals.appState.writeToStorage();
      startNetworking();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => StartupPage(),
            fullscreenDialog: true,
          ),
          (Route _) => false);
    };
  }

  onAddUrl(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        String newUrl;
        return AlertDialog(
          title: Text(getText(context, "action.addbootnodeUrl")),
          content: TextField(
            keyboardType: TextInputType.url,
            onChanged: (value) => newUrl = value,
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
                if (!Uri.parse(newUrl).isAbsolute) {
                  Navigator.of(context).pop(true);
                  showAlert(getText(context, "main.pleaseEnterAValidUrl"),
                      title:
                          getText(context, "error.invalidUrl") + ": " + newUrl,
                      context: context);
                  return;
                }
                List<String> urlList = availableBootnodes.value;
                urlList.add(newUrl);
                availableBootnodes.setValue(urlList);
                Navigator.of(context).pop(true);
              },
            )
          ],
        );
      },
    );
  }
}
