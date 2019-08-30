import 'package:dvote/dvote.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/controllers/ent.dart';
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

makeElementTag({String entityId, String cardId, String elementId}) {
  return entityId + cardId + elementId;
}

onPostCardTap(BuildContext ctx, FeedPost post, Ent ent) {
  Navigator.of(ctx).pushNamed("/entity/feed/post",
      arguments: FeedPostArgs(ent: ent, post: post));
}

buildProcessCard({BuildContext ctx, Ent ent, ProcessMetadata process}) {
  String tag = process.meta['processId'] + process.details.headerImage;

  return BaseCard(
    onTap: () {
      Navigator.pushNamed(ctx, "/entity/participation/poll",
          arguments: PollPageArgs(ent: ent, process: process));
    },
    image: process.details.headerImage,
    imageTag: makeElementTag(
        entityId: ent.entityReference.entityId,
        cardId: process.meta[META_PROCESS_ID],
        elementId: process.details.headerImage),
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
                mainText: "2", secondaryText: " days", purpose: Purpose.GOOD),
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
      buildProcessTitle(ent, process),
    ],
  );
}

Widget buildProcessTitle(Ent ent, ProcessMetadata process) {
  String title = process.details.title[ent.entityMetadata.languages[0]];
  return ListItem(
    // mainTextTag: process.meta['processId'] + title,
    mainText: title,
    mainTextFullWidth: true,
    secondaryText: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
    avatarUrl: ent.entityMetadata.media.avatar,
    avatarHexSource: ent.entityReference.entityId,
    avatarText: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
    rightIcon: null,
  );
}
