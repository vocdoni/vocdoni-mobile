import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:vocdoni/lib/util.dart';
import "package:vocdoni/constants/meta-keys.dart";
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'package:dvote_common/widgets/baseCard.dart';
import 'package:dvote_common/widgets/dashboardItem.dart';
import 'package:dvote_common/widgets/dashboardRow.dart';
import 'package:dvote_common/widgets/dashboardText.dart';
import 'package:dvote_common/widgets/listItem.dart';

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
        .then((_) => this.widget.process.refreshDates())
        .catchError((err) => devPrint(err));
  }

  @override
  Widget build(context) {
    // Consume individual items that may rebuild only themselves
    return EventualBuilder(
      notifiers: [widget.entity.metadata, widget.process.metadata],
      builder: (context, _, __) => this.buildCard(context),
    );
  }

  Widget buildCard(BuildContext context) {
    if (!this.widget.process.metadata.hasValue) return Container();

    String timeLabel = "";
    String timeLeft = "";
    final now = DateTime.now();
    final startDate = this.widget.process.startDate.value;
    final endDate = this.widget.process.endDate.value;

    if (startDate is DateTime && endDate is DateTime) {
      // TODO: CHECK IF CANCELED
      if (now.isAfter(endDate)) {
        timeLabel = getText(context, "Ended");
        timeLeft = getFriendlyTimeDifference(this.widget.process.endDate.value);
      } else if (now.isAfter(startDate)) {
        timeLabel = getText(context, "Time left");
        timeLeft = getFriendlyTimeDifference(this.widget.process.endDate.value);
      } else {
        timeLabel = getText(context, "Starting in");
        timeLeft =
            getFriendlyTimeDifference(this.widget.process.startDate.value);
      }
    } else if (endDate is DateTime) {
      // Refer to endDate
      if (now.isBefore(endDate))
        timeLabel = getText(context, "Ending");
      else
        timeLabel = getText(context, "Ended");

      timeLeft = getFriendlyTimeDifference(this.widget.process.endDate.value);
    } else if (startDate is DateTime) {
      // Refer to startDate
      if (now.isBefore(startDate))
        timeLabel = getText(context, "Starting");
      else
        timeLabel = getText(context, "Started");

      timeLeft = getFriendlyTimeDifference(this.widget.process.startDate.value);
    }

    String participation = "0.0";
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
              label: getText(context, "Vote"),
              item: Icon(
                FeatherIcons.barChart2,
                size: iconSizeMedium,
              ),
            ),
            DashboardItem(
              label: getText(context, "Voted"),
              item: DashboardText(
                  mainText: participation,
                  secondaryText: '%',
                  purpose: Purpose.WARNING),
            ),
            DashboardItem(
              label: timeLabel,
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
      mainTextMultiline: 2,
      mainTextFullWidth: true,
      secondaryText: this.widget.entity.metadata.value.name.values.first,
      avatarUrl: this.widget.entity.metadata.value.media.avatar,
      avatarHexSource: this.widget.entity.reference.entityId,
      avatarText: this.widget.entity.metadata.value.name.values.first,
      rightIcon: null,
    );
  }

  String getFriendlyParticipation(double participation) {
    if (participation == 100.0) return "100";
    return participation.toStringAsPrecision(2);
  }

  String getFriendlyTimeDifference(DateTime date) {
    if (!(date is DateTime)) return throw Exception("Invalid date");

    Duration diff = date.difference(DateTime.now());
    if (diff.isNegative) diff = DateTime.now().difference(date);

    if (diff.inSeconds <= 0)
      return getText(context, "now");
    else if (diff.inDays >= 365)
      return getText(context, "{{NUM}} y")
          .replaceFirst("{{NUM}}", (diff.inDays / 365).floor().toString());
    else if (diff.inDays >= 30)
      return getText(context, "{{NUM}} mo")
          .replaceFirst("{{NUM}}", (diff.inDays / 28).floor().toString());
    else if (diff.inDays >= 1)
      return getText(context, "{{NUM}} d")
          .replaceFirst("{{NUM}}", diff.inDays.toString());
    else if (diff.inHours >= 1)
      return getText(context, "{{NUM}} h")
          .replaceFirst("{{NUM}}", diff.inHours.toString());
    else if (diff.inMinutes >= 1)
      return getText(context, "{{NUM}} min")
          .replaceFirst("{{NUM}}", diff.inMinutes.toString());
    else
      return getText(context, "{{NUM}} s")
          .replaceFirst("{{NUM}}", diff.inSeconds.toString());
  }

  onCardTapped(BuildContext context) {
    Navigator.pushNamed(context, "/entity/participation/poll",
        arguments: PollPageArgs(
            entity: this.widget.entity,
            process: this.widget.process,
            index: this.widget.index));
  }
}
