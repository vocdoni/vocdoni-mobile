import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:intl/intl.dart';

class CardPost extends StatelessWidget {
  final EntityModel entityModel;
  final FeedPost post;
  final int index;

  CardPost(this.entityModel, this.post, [this.index = 0]);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
        onTap: () => onPostCardTap(context, post, entityModel, index),
        image: post.image,
        imageTag:
            makeElementTag(entityModel.reference.entityId, post.id, index),
        children: <Widget>[
          ListItem(
            mainText: post.title,
            mainTextFullWidth: true,
            secondaryText: entityModel
                .metadata.value.name[entityModel.metadata.value.languages[0]],
            avatarUrl: entityModel.metadata.value.media.avatar,
            avatarText: entityModel
                .metadata.value.name[entityModel.metadata.value.languages[0]],
            avatarHexSource: entityModel.reference.entityId,
            rightText: DateFormat('MMMM dd')
                .format(DateTime.parse(post.datePublished).toLocal()),
          )
        ]);
  }

  onPostCardTap(
      BuildContext context, FeedPost post, EntityModel entity, int index) {
    Navigator.of(context).pushNamed("/entity/feed/post",
        arguments: FeedPostArgs(entity: entity, post: post, index: index));
  }
}
