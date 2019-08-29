import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/views/pollPage.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/dashboardItem.dart';
import 'package:vocdoni/widgets/dashboardRow.dart';
import 'package:vocdoni/widgets/dashboardText.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

class EntityParticipation extends StatefulWidget {
  @override
  _EntityParticipationState createState() => _EntityParticipationState();
}

class _EntityParticipationState extends State<EntityParticipation> {
  bool _loading = true;

  @override
  Widget build(context) {
    final Ent ent = ModalRoute.of(context).settings.arguments;
    if (ent.processess == null) return buildNoProcessesess(context);

    return Scaffold(
      appBar: TopNavigation(
        title: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
      ),
      body: ListView.builder(
        itemCount: ent.processess.length,
        itemBuilder: (BuildContext context, int index) {
          final ProcessMetadata process = ent.processess[index];
          String tag = process.meta['processId'] + process.details.headerImage;
          return BaseCard(
            onTap: () {
              Navigator.pushNamed(context, "/entity/participation/poll",
                  arguments: PollPageArgs(ent: ent, process: process));
            },
            image: process.details.headerImage,
            imageTag: tag,
            children: <Widget>[
              DashboardRow(
                children: <Widget>[
                  DashboardItem(
                    label: "Poll",
                    item: Icon(
                      FeatherIcons.barChart2,
                      size: iconSizeMedium,
                    ),
                  ),
                  DashboardItem(
                    label: "Participation",
                    item: DashboardText(
                        mainText: "55",
                        secondaryText: "%",
                        purpose: Purpose.WARNING),
                  ),
                  DashboardItem(
                    label: "Time left",
                    item: DashboardText(
                        mainText: "2",
                        secondaryText: " days",
                        purpose: Purpose.GOOD),
                  ),
                  DashboardItem(
                    label: "Vote now!",
                    item: Icon(
                      FeatherIcons.arrowRightCircle,
                      size: iconSizeMedium,
                      color: getColorByPurpose(purpose: Purpose.HIGHLIGHT),
                    ),
                  ),
                ],
              ),
              buildTitle(ent, process),
            ],
          );
        },
      ),
    );
  }

  Widget buildTitle(Ent ent, ProcessMetadata process) {
    String title = process.details.title[ent.entityMetadata.languages[0]];
    return ListItem(
      // mainTextTag: process.meta['processId'] + title,
      mainText: title,
      mainTextFullWidth: true,
      secondaryText: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
      avatarUrl: ent.entityMetadata.media.avatar,
      avatarHexSource: ent.entitySummary.entityId,
      avatarText: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
      rightIcon: null,
    );
  }

  Widget buildNoProcessesess(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("(No processess)"),
    ));
  }

  Widget buildLoading(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("Loading..."),
    ));
  }
}
