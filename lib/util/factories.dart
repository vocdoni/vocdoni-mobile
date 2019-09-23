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
import 'package:vocdoni/widgets/baseCard.dart';
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

String validUriOrNull(String str) {
  try {
    final uri = Uri.parse(str);
    if (uri.scheme == "") return null;
    return str;
  } catch (e) {
    return null;
  }
}
