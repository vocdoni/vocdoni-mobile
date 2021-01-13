import 'package:dvote/dvote.dart';
import 'package:dvote_common/lib/common.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:dvote_common/widgets/baseCard.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:intl/intl.dart';

class CardPost extends StatelessWidget {
  final EntityModel entity;
  final FeedPost post;
  final int listIdx;

  CardPost(this.post, this.entity, [int listIdx]) : this.listIdx = listIdx ?? 0;

  @override
  Widget build(BuildContext context) {
    String headerUrl = post.image;
    if (headerUrl.startsWith("ipfs"))
      headerUrl =
          processIpfsImageUrl(headerUrl, ipfsDomain: AppConfig.IPFS_DOMAIN);
    String avatarUrl = entity.metadata.value.media.avatar;
    if (avatarUrl.startsWith("ipfs"))
      avatarUrl =
          processIpfsImageUrl(avatarUrl, ipfsDomain: AppConfig.IPFS_DOMAIN);
    // Consume individual items that may rebuild only themselves
    return EventualBuilder(
      notifiers: [entity.metadata, entity.feed],
      builder: (context, _, __) => BaseCard(
          onTap: () => onPostCardTap(context, post, entity),
          image: headerUrl,
          imageTag: makeElementTag(entity.reference.entityId, post.id, listIdx),
          children: <Widget>[
            ListItem(
              mainText: post.title,
              mainTextMultiline: 3,
              mainTextFullWidth: true,
              secondaryText: entity
                  .metadata.value.name[entity.metadata.value.languages[0]],
              avatarUrl: avatarUrl,
              avatarText: entity
                  .metadata.value.name[entity.metadata.value.languages[0]],
              avatarHexSource: entity.reference.entityId,
              rightText: DateFormat('MMM dd')
                  .format(DateTime.parse(post.datePublished).toLocal()),
            )
          ]),
    );
  }

  onPostCardTap(BuildContext context, FeedPost post, EntityModel entity) {
    Navigator.of(context).pushNamed("/entity/feed/post",
        arguments: FeedPostArgs(entity: entity, post: post, listIdx: listIdx));
  }
}
