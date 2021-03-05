import 'package:dvote/constants.dart';
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

EventualNotifier<List<String>> availableDomainSuffixes = EventualNotifier([
  PRODUCTION_ENS_DOMAIN_SUFFIX,
  DEVELOPMENT_ENS_DOMAIN_SUFFIX,
  STAGING_ENS_DOMAIN_SUFFIX,
]);

class EnsDomainSelectPage extends StatefulWidget {
  @override
  _EnsDomainSelectPageState createState() => _EnsDomainSelectPageState();
}

class _EnsDomainSelectPageState extends State<EnsDomainSelectPage> {
  bool isLoadingEnsDomain;
  String currentEnsDomainSuffix;

  @override
  void initState() {
    isLoadingEnsDomain = false;
    currentEnsDomainSuffix = AppConfig.ensDomainSuffix;
    super.initState();
  }

  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "main.ethereumNamespaceDomainSuffix"),
      ),
      body: EventualBuilder(
        notifier: availableDomainSuffixes,
        builder: (BuildContext context, _, __) {
          List<Widget> ensDomainSuffixList = availableDomainSuffixes.value
              .map((suffix) => buildEnsSuffixItem(ctx, suffix))
              .toList();
          if (!availableDomainSuffixes.value.contains(currentEnsDomainSuffix)) {
            ensDomainSuffixList
                .add(buildEnsSuffixItem(ctx, currentEnsDomainSuffix));
          }
          return Column(
            children: [
              Expanded(
                  child: ListView(
                children: ensDomainSuffixList,
              )),
              FloatingActionButton(
                onPressed: () => onAddEnsDomainSuffix(ctx),
                backgroundColor: colorBlue,
                child: Icon(FeatherIcons.plusCircle),
                elevation: 5.0,
                tooltip: getText(ctx, "action.addEnsDomainSuffix"),
              ).withBottomPadding(15),
            ],
          );
        },
      ),
    );
  }

  Widget buildEnsSuffixItem(BuildContext context, String suffix) {
    return ListItem(
        mainText: suffix,
        mainTextMultiline: 3,
        isSpinning: currentEnsDomainSuffix == suffix && isLoadingEnsDomain,
        rightIcon: currentEnsDomainSuffix == suffix
            ? Globals.appState.bootnodeInfo.hasError
                ? FeatherIcons.x
                : FeatherIcons.check
            : FeatherIcons.target,
        onTap: buildOnTap(context, suffix));
  }

  Function() buildOnTap(BuildContext context, String suffix) {
    return () async {
      setState(() {
        currentEnsDomainSuffix = suffix;
        isLoadingEnsDomain = true;
      });
      try {
        await AppConfig.setEnsDomainSuffixOverride(suffix);
        await Globals.appState.refresh();
      } catch (err) {
        logger.log("$err");
        showAlert(
            getText(context, "main.suffix") +
                " " +
                suffix +
                " " +
                getText(context, "main.mayBeInvalid").toLowerCase() +
                " " +
                getText(context, "main.orIncompatibleWithBOOTNODE")
                    .replaceAll("{{BOOTNODE}}", AppConfig.bootnodesUrl)
                    .toLowerCase(),
            title: getText(context, "main.unableToConnectToNetwork"),
            context: context);
        setState(() {
          isLoadingEnsDomain = false;
        });
        return;
      }
      setState(() {
        isLoadingEnsDomain = false;
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

  onAddEnsDomainSuffix(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        String newUrl;
        return AlertDialog(
          title: Text(getText(context, "action.addEnsDomainSuffix")),
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
                List<String> ensDomainSuffixList =
                    availableDomainSuffixes.value;
                ensDomainSuffixList.add(newUrl);
                availableDomainSuffixes.setValue(ensDomainSuffixList);
                Navigator.of(context).pop(true);
              },
            )
          ],
        );
      },
    );
  }
}
