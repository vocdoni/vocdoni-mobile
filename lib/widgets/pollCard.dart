import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/dashboardItem.dart';
import 'package:vocdoni/widgets/dashboardRow.dart';
import 'package:vocdoni/widgets/dashboardText.dart';
import 'package:vocdoni/widgets/listItem.dart';

class PollCard extends StatelessWidget {
  final ProcessModel process;
  final EntModel ent;
  final int index;

  PollCard({this.process, this.ent, this.index});

  @override
  Widget build(ctx) {
    String timeLeft = "";
    String timeUnits = "";
    if (this.process.endDate.isValid) {
      timeUnits =
          getFriendlyTimeLeftUnit(this.process.endDate.value).toString();
      timeLeft =
          getFriendlyTimeLeftNumber(this.process.endDate.value, timeUnits)
              .toString();
    }

    return StateBuilder(
        viewModels: [this.process],
        tag: ProcessTags.PARTICIPATION,
        builder: (ctx, tagId) {
          String participation = "";
          if (this.process.participantsTotal.isValid &&
              this.process.participantsCurrent.isValid)
            participation =
                getFriendlyParticipation(this.process.participation);
          return BaseCard(
            onTap: () {
              Navigator.pushNamed(ctx, "/entity/participation/poll",
                  arguments: PollPageArgs(
                      ent: this.ent,
                      processId: this.process.processId,
                      index: this.index));
            },
            image: validUriOrNull(
                this.process.processMetadata.value.details.headerImage),
            imageTag: makeElementTag(
                this.ent.entityReference.entityId,
                this.process.processMetadata.value.meta[META_PROCESS_ID],
                this.index),
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
                    label: "Voted",
                    item: DashboardText(
                        mainText: participation,
                        secondaryText: '%',
                        purpose: Purpose.WARNING),
                  ),
                  DashboardItem(
                    label: "Time left",
                    item: DashboardText(
                        mainText: timeLeft,
                        secondaryText: timeUnits,
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
              buildProcessTitle(),
            ],
          );
        });
  }

  Widget buildProcessTitle() {
    String title =
        this.process.processMetadata.value.details.title.values.first;
    return ListItem(
      // mainTextTag: process.meta['processId'] + title,
      mainText: title,
      mainTextFullWidth: true,
      secondaryText: this.ent.entityMetadata.value.name.values.first,
      avatarUrl: this.ent.entityMetadata.value.media.avatar,
      avatarHexSource: this.ent.entityReference.entityId,
      avatarText: this.ent.entityMetadata.value.name.values.first,
      rightIcon: null,
    );
  }

  String getFriendlyParticipation(double participation) {
    return participation.round().toString();
  }

  int getFriendlyTimeLeftNumber(DateTime date, String unit) {
    final timeLeft = DateTime.now().difference(date);
    if (unit == 'd')
      return timeLeft.inDays;
    else if (unit == 'h')
      return timeLeft.inHours;
    else if (unit == 'm') return timeLeft.inMinutes;
    return timeLeft.inSeconds;
  }

  String getFriendlyTimeLeftUnit(DateTime date) {
    final timeLeft = DateTime.now().difference(date);
    if (timeLeft.inDays > 2) return 'd';
    if (timeLeft.inHours > 2) return 'h';
    if (timeLeft.inMinutes > 2) return 'm';
    return 's';
  }
}
