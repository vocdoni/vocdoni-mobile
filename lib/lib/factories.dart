import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
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

Widget buildFeedPostCard(
    {BuildContext ctx, EntModel ent, FeedPost post, int index = 0}) {
  return BaseCard(
      onTap: () => onPostCardTap(ctx, post, ent, index),
      image: post.image,
      imageTag: makeElementTag(ent.entityReference.entityId, post.id, index),
      children: <Widget>[
        ListItem(
          mainText: post.title,
          mainTextFullWidth: true,
          secondaryText: ent
              .entityMetadata.value.name[ent.entityMetadata.value.languages[0]],
          avatarUrl: ent.entityMetadata.value.media.avatar,
          avatarText: ent
              .entityMetadata.value.name[ent.entityMetadata.value.languages[0]],
          avatarHexSource: ent.entityReference.entityId,
          rightText: DateFormat('MMMM dd')
              .format(DateTime.parse(post.datePublished).toLocal()),
        )
      ]);
}

makeElementTag(String entityId, String itemId, int index) {
  return entityId + "/" + itemId + "/" + (index ?? '').toString();
}

onPostCardTap(BuildContext ctx, FeedPost post, EntModel ent, int index) {
  Navigator.of(ctx).pushNamed("/entity/feed/post",
      arguments: FeedPostArgs(ent: ent, post: post, index: index));
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
