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

class PollCard extends StatefulWidget {
  final ProcessModel process;
  final EntModel ent;

  PollCard({this.process, this.ent});

  @override
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(ctx) {
    String timeLeft="";
    String timeUnits="";
    if (widget.process.endDate.isValid) {
     
      timeUnits = getFriendlyTimeLeftUnit(widget.process.endDate.value).toString();
      timeLeft = getFriendlyTimeLeftNumber(widget.process.endDate.value, timeUnits).toString();
    }

    return StateBuilder(
        viewModels: [widget.process],
        tag: ProcessTags.PARTICIPATION,
        builder: (ctx, tagId) {
          String participation = "";
          if (widget.process.participantsTotal.isValid && widget.process.participantsCurrent.isValid)
            participation =
                getFriendlyParticipation(widget.process.participation);
          return BaseCard(
            onTap: () {
              Navigator.pushNamed(ctx, "/entity/participation/poll",
                  arguments: PollPageArgs(
                      ent: widget.ent, processId: widget.process.processId));
            },
            image: validUriOrNull(
                widget.process.processMetadata.value.details.headerImage),
            imageTag: makeElementTag(
                entityId: widget.ent.entityReference.entityId,
                cardId: widget.process.processMetadata.value.meta[META_PROCESS_ID],
                elementId: widget.process.processMetadata.value.details.headerImage),
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
    String title = widget.process.processMetadata.value.details.title.values.first;
    return ListItem(
      // mainTextTag: process.meta['processId'] + title,
      mainText: title,
      mainTextFullWidth: true,
      secondaryText: widget.ent.entityMetadata.value.name.values.first,
      avatarUrl: widget.ent.entityMetadata.value.media.avatar,
      avatarHexSource: widget.ent.entityReference.entityId,
      avatarText: widget.ent.entityMetadata.value.name.values.first,
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
