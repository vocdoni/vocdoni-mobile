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

EventualNotifier<List<String>> availableNetworks = EventualNotifier([
  "xdai",
  "goerli",
  "sokol",
]);

class NetworkSelectPage extends StatefulWidget {
  @override
  _NetworkSelectPageState createState() => _NetworkSelectPageState();
}

class _NetworkSelectPageState extends State<NetworkSelectPage> {
  bool isLoadingNetwork;
  String currentNetworkId;

  @override
  void initState() {
    isLoadingNetwork = false;
    currentNetworkId = AppConfig.networkId;
    super.initState();
  }

  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "main.networkId"),
      ),
      body: EventualBuilder(
        notifier: availableNetworks,
        builder: (BuildContext context, _, __) {
          List<Widget> networkIdList = availableNetworks.value
              .map((networkId) => buildNetworkItem(ctx, networkId))
              .toList();
          if (!availableNetworks.value.contains(currentNetworkId)) {
            networkIdList.add(buildNetworkItem(ctx, currentNetworkId));
          }
          return Column(
            children: [
              Expanded(
                  child: ListView(
                children: networkIdList,
              )),
              FloatingActionButton(
                onPressed: () => onAddNetwork(ctx),
                backgroundColor: colorBlue,
                child: Icon(FeatherIcons.plusCircle),
                elevation: 5.0,
                tooltip: getText(ctx, "action.addNetworkId"),
              ).withBottomPadding(15),
            ],
          );
        },
      ),
    );
  }

  Widget buildNetworkItem(BuildContext context, String networkId) {
    return ListItem(
        mainText: networkId,
        mainTextMultiline: 3,
        isSpinning: currentNetworkId == networkId && isLoadingNetwork,
        rightIcon: currentNetworkId == networkId
            ? Globals.appState.bootnodeInfo.hasError
                ? FeatherIcons.x
                : FeatherIcons.check
            : FeatherIcons.target,
        onTap: buildOnTap(context, networkId));
  }

  Function() buildOnTap(BuildContext context, String networkId) {
    return () async {
      setState(() {
        currentNetworkId = networkId;
        isLoadingNetwork = true;
      });
      try {
        await AppConfig.setNetworkOverride(networkId);
      } catch (err) {
        logger.log("$err");
        showAlert(
            getText(context, "main.networkId") +
                " " +
                networkId +
                " " +
                getText(context, "main.mayBeInvalid").toLowerCase() +
                " " +
                getText(context, "main.orIncompatibleWithBOOTNODE")
                    .replaceAll("{{BOOTNODE}}", AppConfig.bootnodesUrl)
                    .toLowerCase(),
            title: getText(context, "main.unableToConnectToNetwork"),
            context: context);
        setState(() {
          isLoadingNetwork = false;
        });
        return;
      }
      setState(() {
        isLoadingNetwork = false;
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

  onAddNetwork(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        String newUrl;
        return AlertDialog(
          title: Text(getText(context, "action.addNetworkId")),
          content: TextField(
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
                List<String> networkIdList = availableNetworks.value;
                networkIdList.add(newUrl);
                availableNetworks.setValue(networkIdList);
                Navigator.of(context).pop(true);
              },
            )
          ],
        );
      },
    );
  }
}
