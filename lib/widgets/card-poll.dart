import 'dart:async';

import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/makers.dart';
import "dart:developer";
import "package:vocdoni/constants/meta-keys.dart";
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'package:dvote_common/widgets/baseCard.dart';
import 'package:dvote_common/widgets/dashboardItem.dart';
import 'package:dvote_common/widgets/dashboardRow.dart';
import 'package:dvote_common/widgets/dashboardText.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/spinner.dart';

class CardPoll extends StatefulWidget {
  final ProcessModel process;
  final EntityModel entity;
  final int listIdx;

  CardPoll(this.process, this.entity, [this.listIdx = 0]);

  @override
  _CardPollState createState() => _CardPollState();
}

class _CardPollState extends State<CardPoll> {
  Timer refreshCheck;
  int refreshCounter = 0;

  @override
  void initState() {
    refreshCheck = Timer.periodic(Duration(seconds: 1), (_) async {
      refreshCounter++;
      final isStartingOrEnding =
          this.widget.process.startDate.value.isAfter(DateTime.now()) &&
                  this
                      .widget
                      .process
                      .startDate
                      .value
                      .isBefore(DateTime.now().add(Duration(minutes: 1))) ||
              this.widget.process.endDate.value.isAfter(DateTime.now()) &&
                  this
                      .widget
                      .process
                      .endDate
                      .value
                      .isBefore(DateTime.now().add(Duration(minutes: 1)));
      // Refresh dates every second when process is near to starting or ending time
      await this.widget.process.refreshDates(force: isStartingOrEnding);
      // Refresh everything else every 30 seconds, if process is active
      if (refreshCounter % 30 == 0 &&
          this.widget.process.startDate.value.isBefore(DateTime.now()) &&
          this
              .widget
              .process
              .endDate
              .value
              .isAfter(DateTime.now().add(Duration(minutes: -1)))) {
        await this.widget.process.refreshCurrentParticipants();
      }
    });

    super.initState();

    this
        .widget
        .process
        .refreshCurrentParticipants()
        .then((_) => this.widget.process.refreshCensusSize())
        .then((_) => this.widget.process.refreshDates())
        .catchError((err) => log(err));
  }

  @override
  void dispose() {
    if (refreshCheck is Timer) refreshCheck.cancel();

    super.dispose();
  }

  @override
  Widget build(context) {
    // Consume individual items that may rebuild only themselves
    return EventualBuilder(
      notifiers: [
        widget.entity.metadata,
        widget.process.metadata,
        widget.process.startDate,
        widget.process.endDate,
        widget.process.censusSize,
        widget.process.currentParticipants
      ],
      builder: (context, _, __) => this.buildCard(context),
    );
  }

  Widget buildCard(BuildContext context) {
    if (!this.widget.process.metadata.hasValue) return Container();

    String timeLabel = getText(context, "main.starting");
    String timeLeft = "-";
    final now = DateTime.now();
    final startDate = this.widget.process.startDate.value;
    final endDate = this.widget.process.endDate.value;
    bool dateLoaded = false;

    if (startDate is DateTime && endDate is DateTime) {
      // TODO: CHECK IF CANCELED
      if (now.isAfter(endDate)) {
        timeLabel = getText(context, "main.ended");
        timeLeft = getFriendlyTimeDifference(this.widget.process.endDate.value);
      } else if (now.isAfter(startDate)) {
        timeLabel = getText(context, "main.timeLeft");
        timeLeft = getFriendlyTimeDifference(this.widget.process.endDate.value);
      } else {
        timeLabel = getText(context, "main.startingIn");
        timeLeft =
            getFriendlyTimeDifference(this.widget.process.startDate.value);
      }
      dateLoaded = true;
    } else if (endDate is DateTime) {
      // Refer to endDate
      if (now.isBefore(endDate))
        timeLabel = getText(context, "main.ending");
      else
        timeLabel = getText(context, "main.ended");

      timeLeft = getFriendlyTimeDifference(this.widget.process.endDate.value);
      dateLoaded = true;
    } else if (startDate is DateTime) {
      // Refer to startDate
      if (now.isBefore(startDate))
        timeLabel = getText(context, "main.starting");
      else
        timeLabel = getText(context, "main.started");

      timeLeft = getFriendlyTimeDifference(this.widget.process.startDate.value);
      dateLoaded = true;
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
          this.widget.listIdx),
      children: <Widget>[
        DashboardRow(
          children: <Widget>[
            DashboardItem(
              label: getText(context, "main.vote"),
              item: Icon(
                FeatherIcons.barChart2,
                size: iconSizeMedium,
              ),
            ),
            DashboardItem(
              label: getText(context, "main.voted"),
              item: DashboardText(
                  mainText: participation,
                  secondaryText: '%',
                  purpose: Purpose.WARNING),
            ),
            DashboardItem(
              label: timeLabel,
              item: dateLoaded
                  ? DashboardText(
                      mainText: timeLeft,
                      secondaryText: "",
                      purpose: Purpose.GOOD)
                  : SpinnerCircular(),
            ),
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
      return getText(context, "main.now");
    else if (diff.inDays >= 365)
      return getText(context, "main.numY")
          .replaceFirst("{{NUM}}", (diff.inDays / 365).floor().toString());
    else if (diff.inDays >= 30)
      return getText(context, "main.numMo")
          .replaceFirst("{{NUM}}", (diff.inDays / 28).floor().toString());
    else if (diff.inDays >= 1)
      return getText(context, "main.numD")
          .replaceFirst("{{NUM}}", diff.inDays.toString());
    else if (diff.inHours >= 1)
      return getText(context, "main.numH")
          .replaceFirst("{{NUM}}", diff.inHours.toString());
    else if (diff.inMinutes >= 1)
      return getText(context, "main.numMin")
          .replaceFirst("{{NUM}}", (diff.inMinutes + 1).toString());
    else
      return getText(context, "main.numS")
          .replaceFirst("{{NUM}}", "~" + diff.inSeconds.toString());
  }

  onCardTapped(BuildContext context) {
    Navigator.pushNamed(context, "/entity/participation/poll",
        arguments: PollPageArgs(
            entity: this.widget.entity,
            process: this.widget.process,
            listIdx: this.widget.listIdx));
  }
}
