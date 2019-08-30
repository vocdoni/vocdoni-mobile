import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
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

Widget buildFeedPostCard(BuildContext ctx, Ent ent, FeedPost post) {
  return BaseCard(
      image: post.image,
      imageTag: post.id + post.image,
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
          onTap: () => onPostCardTap(ctx, post),
        )
      ]);
}

onPostCardTap(BuildContext ctx, FeedPost post) {
  Navigator.of(ctx)
      .pushNamed("/entity/feed/post", arguments: FeedPostArgs(post));
}
