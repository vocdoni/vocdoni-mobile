import 'package:dvote/dvote.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/makers.dart';
import "package:vocdoni/constants/meta-keys.dart";
import 'package:vocdoni/views/poll-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/dashboardItem.dart';
import 'package:vocdoni/widgets/dashboardRow.dart';
import 'package:vocdoni/widgets/dashboardText.dart';
import 'package:vocdoni/widgets/listItem.dart';

class CardPoll extends StatelessWidget {
  final ProcessModel process;
  final EntityModel entity;
  final int index;

  CardPoll(
      {@required this.process, @required this.entity, @required this.index});

  @override
  Widget build(context) {
    // Consume individual items that may rebuild only themselves
    return ChangeNotifierProvider.value(
        value: entity.metadata,
        child: ChangeNotifierProvider.value(
          value: process.metadata,
          child: this.buildCard(context),
        ));
  }

  Widget buildCard(BuildContext context) {
    String timeLeft = "";
    if (this.process.endDate is DateTime) {
      timeLeft = getFriendlyTimeLeft(this.process.endDate);
    }

    String participation = "";
    if (this.process.censusSize.hasValue &&
        this.process.currentParticipants.hasValue)
      participation =
          getFriendlyParticipation(this.process.currentParticipation);

    return BaseCard(
      onTap: () => this.onCardTapped(context),
      image: Uri.tryParse(this.process.metadata.value?.details?.headerImage)
          ?.toString(),
      imageTag: makeElementTag(this.entity.reference.entityId,
          this.process.metadata.value?.meta[META_PROCESS_ID], this.index),
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
  }

  Widget buildProcessTitle() {
    String title = this.process.metadata.value.details.title.values.first;
    return ListItem(
      // mainTextTag: process.meta['processId'] + title,
      mainText: title,
      mainTextFullWidth: true,
      secondaryText: this.entity.metadata.value.name.values.first,
      avatarUrl: this.entity.metadata.value.media.avatar,
      avatarHexSource: this.entity.reference.entityId,
      avatarText: this.entity.metadata.value.name.values.first,
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

  onCardTapped(BuildContext context) {
    Navigator.pushNamed(context, "/entity/participation/poll",
        arguments: PollPageArgs(
            entity: this.entity,
            processId: this.process.processId,
            index: this.index));
  }
}
