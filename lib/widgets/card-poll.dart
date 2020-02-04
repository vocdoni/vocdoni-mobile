import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:vocdoni/lib/util.dart';
import "package:vocdoni/constants/meta-keys.dart";
import 'package:vocdoni/lib/state-notifier-listener.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/dashboardItem.dart';
import 'package:vocdoni/widgets/dashboardRow.dart';
import 'package:vocdoni/widgets/dashboardText.dart';
import 'package:vocdoni/widgets/listItem.dart';

class CardPoll extends StatefulWidget {
  final ProcessModel process;
  final EntityModel entity;
  final int index;

  CardPoll(
      {@required this.process, @required this.entity, @required this.index});

  @override
  _CardPollState createState() => _CardPollState();
}

class _CardPollState extends State<CardPoll> {
  @override
  void initState() {
    super.initState();

    this
        .widget
        .process
        .refreshCurrentParticipants()
        .then((_) => this.widget.process.refreshCensusSize())
        .catchError((err) => devPrint(err));
  }

  @override
  Widget build(context) {
    // Consume individual items that may rebuild only themselves
    return StateNotifierListener(
      values: [widget.entity.metadata, widget.process.metadata],
      builder: (context) => this.buildCard(context),
    );
  }

  Widget buildCard(BuildContext context) {
    if (!this.widget.process.metadata.hasValue) return Container();

    String timeLeft = "";
    if (this.widget.process.endDate is DateTime) {
      timeLeft = getFriendlyTimeLeft(this.widget.process.endDate);
    }

    String participation = "";
    if (this.widget.process.censusSize.hasValue &&
        this.widget.process.currentParticipants.hasValue) {
      participation =
          getFriendlyParticipation(this.widget.process.currentParticipation);
    }

    return BaseCard(
      onTap: () => this.onCardTapped(context),
      image: Uri.tryParse(
              this.widget.process.metadata.value?.details?.headerImage ?? "")
          ?.toString(),
      imageTag: makeElementTag(
          this.widget.entity.reference.entityId,
          this.widget.process.metadata.value?.meta[META_PROCESS_ID],
          this.widget.index),
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
                  mainText: timeLeft, secondaryText: "", purpose: Purpose.GOOD),
            ),
            // DashboardItem(
            //   label: "Vote now!",
            //   item: Icon(
            //     FeatherIcons.arrowRightCircle,
            //     size: iconSizeMedium,
            //     color: getColorByPurpose(purpose: Purpose.HIGHLIGHT),
            //   ),
            // ),
          ],
        ),
        buildProcessTitle(),
      ],
    );
  }

  Widget buildProcessTitle() {
    String title =
        this.widget.process.metadata.value.details.title.values.first;
    return ListItem(
      // mainTextTag: process.meta['processId'] + title,
      mainText: title,
      mainTextFullWidth: true,
      secondaryText: this.widget.entity.metadata.value.name.values.first,
      avatarUrl: this.widget.entity.metadata.value.media.avatar,
      avatarHexSource: this.widget.entity.reference.entityId,
      avatarText: this.widget.entity.metadata.value.name.values.first,
      rightIcon: null,
    );
  }

  String getFriendlyParticipation(double participation) {
    return participation.toStringAsPrecision(2);
  }

  String getFriendlyTimeLeft(DateTime date) {
    if (!(date is DateTime)) return throw Exception("Invlaid date");

    final timeLeft = date.difference(DateTime.now());
    if (timeLeft.inSeconds <= 0)
      return "-";
    else if (timeLeft.inDays >= 365)
      return "" + (timeLeft.inDays / 365).floor().toString() + "y";
    else if (timeLeft.inDays >= 30)
      return "" + (timeLeft.inDays / 28).floor().toString() + "mo";
    else if (timeLeft.inDays >= 1)
      return timeLeft.inDays.toString() + "d";
    else if (timeLeft.inHours >= 1)
      return timeLeft.inHours.toString() + "h";
    else if (timeLeft.inMinutes >= 1)
      return timeLeft.inMinutes.toString() + "min";
    else
      return timeLeft.inSeconds.toString() + "s";
  }

  onCardTapped(BuildContext context) {
    Navigator.pushNamed(context, "/entity/participation/poll",
        arguments: PollPageArgs(
            entity: this.widget.entity,
            process: this.widget.process,
            index: this.widget.index));
  }
}
