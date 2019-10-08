import 'package:dvote/models/dart/process.pb.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/controllers/processModel.dart';
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
  final Ent ent;

  PollCard({this.process, this.ent});

  @override
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {

  @override
  void initState() {
    super.initState();
    widget.process.updateParticipation();
  }

  @override
  Widget build(ctx) {
    final endDate = widget.process.getEndDate();
    String timeUnits = endDate != null ? getFriendlyTimeLeftUnit(endDate) : "";
    int timeLeft =
        endDate != null ? getFriendlyTimeLeftNumber(endDate, timeUnits) : 0;

    return StateBuilder(
        viewModels: [widget.process],
        tag: ProcessTags.PARTICIPATION,
        builder: (ctx, tagId) {
          return BaseCard(
            onTap: () {
              Navigator.pushNamed(ctx, "/entity/participation/poll",
                  arguments:
                      PollPageArgs(ent: widget.ent, process: widget.process));
            },
            image: validUriOrNull(
                widget.process.processMetadata.details.headerImage),
            imageTag: makeElementTag(
                entityId: widget.ent.entityReference.entityId,
                cardId: widget.process.processMetadata.meta[META_PROCESS_ID],
                elementId: widget.process.processMetadata.details.headerImage),
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
                        mainText: getFriendlyParticipation(widget.process.participation),
                        secondaryText:'%',
                        purpose: Purpose.WARNING),
                  ),
                  DashboardItem(
                    label: "Time left",
                    item: DashboardText(
                        mainText: timeLeft.toString(),
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
              buildProcessTitle(widget.ent, widget.process.processMetadata),
            ],
          );
        });
  }

  Widget buildProcessTitle(Ent ent, ProcessMetadata process) {
    String title = process.details.title.values.first;
    return ListItem(
      // mainTextTag: process.meta['processId'] + title,
      mainText: title,
      mainTextFullWidth: true,
      secondaryText: ent.entityMetadata.name.values.first,
      avatarUrl: ent.entityMetadata.media.avatar,
      avatarHexSource: ent.entityReference.entityId,
      avatarText: ent.entityMetadata.name.values.first,
      rightIcon: null,
    );
  }

  String getFriendlyParticipation(double participation ){
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
