import 'package:dvote/dvote.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/controllers/process.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/views/poll-page.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/dashboardItem.dart';
import 'package:vocdoni/widgets/dashboardRow.dart';
import 'package:vocdoni/widgets/dashboardText.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:intl/intl.dart';

EntityReference makeEntityReference(
    {String entityId, String resolverAddress, List<String> entryPoints}) {
  EntityReference summary = EntityReference();
  summary.entityId = entityId;
  summary.entryPoints.addAll(entryPoints ?? []);
  return summary;
}

Widget buildFeedPostCard({BuildContext ctx, Ent ent, FeedPost post}) {
  return BaseCard(
      onTap: () => onPostCardTap(ctx, post, ent),
      image: post.image,
      imageTag: makeElementTag(
          entityId: ent.entityReference.entityId,
          cardId: post.id,
          elementId: post.image),
      children: <Widget>[
        ListItem(
          mainText: post.title,
          mainTextFullWidth: true,
          secondaryText:
              ent.entityMetadata.name[ent.entityMetadata.languages[0]],
          avatarUrl: ent.entityMetadata.media.avatar,
          avatarText: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
          avatarHexSource: ent.entityReference.entityId,
          rightText: DateFormat('MMMM dd')
              .format(DateTime.parse(post.datePublished).toLocal()),
        )
      ]);
}

getFriendlyTimeLeft(int seconds) {
  return seconds;
}

//TODO use dvote api instead once they removed getEnvelopHeight
int getSecondsUntilBlock(
    DateTime referenceTimeStamp, int referenceBlock, int blockNumber) {
  int blocksLeftFromReference = blockNumber - referenceBlock;
  Duration referenceToBlock = blocksToDuration(blocksLeftFromReference);
  Duration nowToReference = DateTime.now().difference(referenceTimeStamp);
  return referenceToBlock.inSeconds - nowToReference.inSeconds;
}

Duration blocksToDuration(int blocks) {
  int averageBlockTime = 5; //seconds
  return new Duration(seconds: averageBlockTime * blocks);
}

makeElementTag({String entityId, String cardId, String elementId}) {
  return entityId + cardId + elementId;
}

onPostCardTap(BuildContext ctx, FeedPost post, Ent ent) {
  Navigator.of(ctx).pushNamed("/entity/feed/post",
      arguments: FeedPostArgs(ent: ent, post: post));
}

String validUriOrNull(String str) {
  try {
    final uri = Uri.parse(str);
    if (uri.scheme == "") return null;
    return str;
  } catch (e) {
    return null;
  }
}

buildProcessCard({BuildContext ctx, Ent ent, Process process}) {
  //
  final gwInfo = selectRandomGatewayInfo();

  //TODO Do not open a connection to check each process time
  final DVoteGateway dvoteGw =
      DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);
  int timeLeft = 0;
  /*getProcessRemainingTime(process.meta[META_PROCESS_ID],process.startBlock, process.numberOfBlocks, dvoteGw).then((timeLeft){
    //TODO set timeleft
  });*/
  return BaseCard(
    onTap: () {
      Navigator.pushNamed(ctx, "/entity/participation/poll",
          arguments: PollPageArgs(ent: ent, process: process));
    },
    image: validUriOrNull(process.processMetadata.details.headerImage),
    imageTag: makeElementTag(
        entityId: ent.entityReference.entityId,
        cardId: process.processMetadata.meta[META_PROCESS_ID],
        elementId: process.processMetadata.details.headerImage),
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
                mainText: "55", secondaryText: "%", purpose: Purpose.WARNING),
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
      buildProcessTitle(ent, process.processMetadata),
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
