import 'package:dvote/api/voting.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/overlays.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/lib/app-links.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/dev/populate.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/notifications.dart';
import 'package:vocdoni/view-modals/bootnode-select.dart';

class DevMenu extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: "Developer",
      ),
      body: Builder(
        builder: (BuildContext context) => ListView(
          children: <Widget>[
            ListItem(
              mainText: getText(context, "main.setBootnodesUrl"),
              onTap: () {
                Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => BootnodeSelectPage()));
              },
            ),
            ListItem(
                mainText: "Show message overlay",
                onTap: () {
                  showMessageOverlay(
                      getText(Globals.navigatorKey.currentContext,
                          "error.unableToConnectToGatewaysTheBootnodeUrlOrBlockchainNetworkIdMayBeInvalid"),
                      purpose: Purpose.DANGER);
                }),
            ListItem(
                mainText: "Add fake organizations",
                onTap: () {
                  populateSampleData();
                }),
            ListItem(
              mainText: "ListItem variations (UI)",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/ui-listItem");
              },
            ),
            ListItem(
              mainText: "Cards variations (UI)",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/ui-card");
              },
            ),
            ListItem(
              mainText: "Avatar color generation (UI)",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/ui-avatar-colors");
              },
            ),
            ListItem(
              mainText: "Handle deeplink (Esqueixada)",
              onTap: () {
                String link =
                    'https://app.vocdoni.net/entities/#/0x8dfbc9c552338427b13ae755758bb5fd7df4fce0f98ceff56c791e5b74fcffba';
                handleIncomingLink(Uri.parse(link), context);
              },
            ),
            ListItem(
              mainText: "Handle deeplink (VocdoniTest)",
              onTap: () {
                String link =
                    'https://app.vocdoni.net/entities/#/0x33e9ee1a35cc74dee64e13b46db4f52d61bb450a71cfcb810a3175d1f308f658';
                handleIncomingLink(Uri.parse(link), context);
              },
            ),
            ListItem(
              mainText: "Handle deeplink (Account Recovery)",
              onTap: () {
                String link = 'https://app.vocdoni.net/recovery/';
                handleIncomingLink(Uri.parse(link), context);
              },
            ),
            ListItem(
              mainText: "Handle deeplink (Validation)",
              onTap: () {
                String link =
                    'https://vocdoni.link/validation/0x58574d7e6d07ce0aa68ea7e96f4a7287fe53c56deee7b787fd5f0926d0d80314/b0558fb8-9852-4fe1-807b-931cf171f7cd';
                handleIncomingLink(Uri.parse(link), context);
              },
            ),
            ListItem(
              mainText: "Handle deeplink (dev entity)",
              onTap: () {
                String link =
                    'https://dev.vocdoni.link/entities/0x63c1452CF8F2fEd7ead5e6C222C41E96c6ec1E0F';
                handleIncomingLink(Uri.parse(link), context);
              },
            ),
            ListItem(
              mainText: "Parse process data (dev entity)",
              onTap: () async {
                await getProcess(
                    "0x7f490c31177f8e57bedc7817eb12215830fd554d5d9a925525a92aa7408cd690",
                    AppNetworking.pool);
              },
            ),
            ListItem(
                mainText: "Handle post notification",
                onTap: () {
                  Notifications.onResume({
                    "gcm.message_id": "1607027839009912",
                    "message": "MA Coop posted: noties",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    "google.c.a.e": 1,
                    "uri":
                        "https://app.vocdoni.link/posts/0x58574d7e6d07ce0aa68ea7e96f4a7287fe53c56deee7b787fd5f0926d0d80314/1607025505147",
                    "aps": {
                      "alert": {
                        "title": "New post created",
                        "body": "MA Coop posted: noties"
                      }
                    }
                  });
                }),
            ListItem(
                mainText: "Handle process notification",
                onTap: () {
                  Notifications.onResume({
                    "gcm.message_id": "1607027839009912",
                    "message": " created a new voting process",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    "google.c.a.e": 1,
                    "uri":
                        "https://app.vocdoni.link/processes/0x58574d7e6d07ce0aa68ea7e96f4a7287fe53c56deee7b787fd5f0926d0d80314/0x1a2b8b62f45ad3dc9cc3d51f3edbc8cc6490820c8224c780153528b39768c6c6",
                    "aps": {
                      "alert": {
                        "title": "New process created",
                        "body": "Entity created a new voting process"
                      }
                    }
                  });
                }),
            ListItem(
              mainText: "Analytics",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/analytics-tests");
              },
            ),
            ListItem(
              mainText: "Pager test",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/pager");
              },
            ),
            // ListItem(
            //   mainText: "Track account a",
            //   onTap: () async {
            //     Globals.analytics.user$.add("aaaaaa");
            //     await Globals.analytics.mixpanelBatch.engage(
            //       operation: MixpanelUpdateOperations.$set,
            //       value: {
            //         "AppVersion": "TestApp",
            //       },
            //     );
            //     Globals.analytics.trackEvent("TESTEVENTB");
            //   },
            // ),
            // ListItem(
            //   mainText: "Track account b",
            //   onTap: () async {
            //     Globals.analytics.user$.add("bbbbbb");
            //     await Globals.analytics.mixpanelBatch.engage(
            //       operation: MixpanelUpdateOperations.$set,
            //       value: {
            //         "AppVersion": "TestApp",
            //       },
            //     );
            //     Globals.analytics.trackEvent("TESTEVENTA");
            //   },
            // ),
            // ListItem(
            //   mainText: "Track account c",
            //   onTap: () async {
            //     // Globals.analytics.user$.add("cccccc");
            //     await Globals.analytics.init();
            //     Globals.analytics.user$.add("cccccc");
            //     await Globals.analytics.mixpanelBatch.engage(
            //       operation: MixpanelUpdateOperations.$set,
            //       value: {
            //         "AppVersion": "TestApp",
            //       },
            //     );
            //     Globals.analytics.trackEvent("TESTEVENTC");
            //   },
            // ),
            // ListItem(
            //   mainText: "Track account d",
            //   onTap: () async {
            //     // Globals.analytics.user$.add("dddddd");
            //     await Globals.analytics.init();
            //     Globals.analytics.user$.add("dddddd");
            //     await Globals.analytics.mixpanelBatch.engage(
            //       operation: MixpanelUpdateOperations.$set,
            //       value: {
            //         "AppVersion": "TestApp",
            //       },
            //     );
            //     Globals.analytics.trackEvent("TESTEVENTD");
            //   },
            // ),
            ListItem(
                mainText: "In-app notif test",
                onTap: () {
                  Notifications.onMessage({
                    "gcm.message_id": "1607027839009912",
                    "message": " created a new voting process",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    "google.c.a.e": 1,
                    "data": {
                      "uri":
                          "https://app.vocdoni.link/processes/0x58574d7e6d07ce0aa68ea7e96f4a7287fe53c56deee7b787fd5f0926d0d80314/0x1a2b8b62f45ad3dc9cc3d51f3edbc8cc6490820c8224c780153528b39768c6c6",
                      "aps": {
                        "alert": {
                          "title": "New process created",
                          "body": "Entity created a new voting process"
                        }
                      }
                    }
                  });
                }),
          ],
        ),
      ),
    );
  }
}
