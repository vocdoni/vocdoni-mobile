import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/data-models/entModel.dart';
import 'package:vocdoni/data-models/processModel.dart';
import 'package:vocdoni/lib/factories.dart';
import "package:vocdoni/constants/meta.dart";
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

  PollCard({@required this.process, @required this.ent, @required this.index});

  @override
  Widget build(ctx) {
    String timeLeft = "";
    if (this.process.endDate.hasValue) {
      timeLeft = getFriendlyTimeLeft(this.process.endDate.value);
    }

    return StateBuilder(
        viewModels: [this.process],
        tag: ProcessTags.PARTICIPATION,
        builder: (ctx, tagId) {
          String participation = "";
          if (this.process.participantsTotal.hasValue &&
              this.process.participantsCurrent.hasValue)
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
                this.process.processMetadata.value?.details?.headerImage),
            imageTag: makeElementTag(
                this.ent.entityReference.entityId,
                this.process.processMetadata.value?.meta[META_PROCESS_ID],
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
                        secondaryText: "",
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

  String getFriendlyTimeLeft(DateTime date) {
    final timeLeft = DateTime.now().difference(date);
    if (timeLeft.inSeconds <= 0)
      return "-";
    else if (timeLeft.inDays >= 365)
      return "" + (timeLeft.inDays / 365).floor().toString() + "y";
    else if (timeLeft.inDays >= 30)
      return "" + (timeLeft.inDays / 28).floor().toString() + "m";
    else if (timeLeft.inDays >= 1)
      return timeLeft.inDays.toString() + "d";
    else if (timeLeft.inHours >= 1)
      return timeLeft.inHours.toString() + "h";
    else if (timeLeft.inMinutes >= 1)
      return timeLeft.inMinutes.toString() + "min";
    else
      return timeLeft.inSeconds.toString() + "s";
  }
}
