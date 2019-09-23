import 'package:dvote/models/dart/process.pb.dart';
import 'package:dvote/net/gateway.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/controllers/process.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/dashboardItem.dart';
import 'package:vocdoni/widgets/dashboardRow.dart';
import 'package:vocdoni/widgets/dashboardText.dart';
import 'package:vocdoni/widgets/listItem.dart';

class PollCard extends StatefulWidget {
  final Process process;
  final Ent ent;

  PollCard({this.process, this.ent});

  @override
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  String _participation = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _participation = "?";
    updatePartcipation();
  }

  updatePartcipation() async {
    double p = await widget.process.getParticipation();
    setState(() {
      _participation = p.toString();
    });
  }

  @override
  Widget build(ctx) {
    // Widget build({BuildContext ctx, Ent ent, Process process}) {
    final gwInfo = selectRandomGatewayInfo();

    //TODO Do not open a connection to check each process time
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    String timeUnits = getFriendlyTimeLeftUnit(widget.process.getEndDate());
    int timeLeft =
        getFriendlyTimeLeftNumber(widget.process.getEndDate(), timeUnits);
    /*getProcessRemainingTime(process.meta[META_PROCESS_ID],process.startBlock, process.numberOfBlocks, dvoteGw).then((timeLeft){
    //TODO set timeleft
  });*/
    return BaseCard(
      onTap: () {
        Navigator.pushNamed(ctx, "/entity/participation/poll",
            arguments: PollPageArgs(ent: widget.ent, process: widget.process));
      },
      image: validUriOrNull(widget.process.processMetadata.details.headerImage),
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
                  mainText: _participation, secondaryText: "%", purpose: Purpose.WARNING),
            ),
            DashboardItem(
              label: "Time left",
              item: DashboardText(
                  mainText: timeLeft.toString(),
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
        buildProcessTitle(widget.ent, widget.process.processMetadata),
      ],
    );
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

  getFriendlyTimeLeftNumber(DateTime date, String unit) {
    final timeLeft = DateTime.now().difference(date);
    if (unit == 'days') return timeLeft.inDays;
    if (unit == 'hours') return timeLeft.inHours;
    if (unit == 'min') return timeLeft.inMinutes;
    return timeLeft.inSeconds;
  }

  getFriendlyTimeLeftUnit(DateTime date) {
    final timeLeft = DateTime.now().difference(date);
    if (timeLeft.inDays > 2) return 'days';
    if (timeLeft.inHours > 2) return 'hours';
    if (timeLeft.inMinutes > 2) return 'min';
    return 'sec';
  }
}
