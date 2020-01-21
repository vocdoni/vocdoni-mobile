import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:intl/intl.dart';

class CardPost extends StatelessWidget {
  final EntityModel entity;
  final FeedPost post;
  final int index;

  CardPost(this.entity, this.post, [this.index = 0]);

  @override
  Widget build(BuildContext context) {
    // Consume individual items that may rebuild only themselves
    return ChangeNotifierProvider.value(
      value: entity.metadata,
      child: ChangeNotifierProvider.value(
        value: entity.feed.value.feed,
        child: BaseCard(
            onTap: () => onPostCardTap(context, post, entity, index),
            image: post.image,
            imageTag: makeElementTag(entity.reference.entityId, post.id, index),
            children: <Widget>[
              ListItem(
                mainText: post.title,
                mainTextFullWidth: true,
                secondaryText: entity
                    .metadata.value.name[entity.metadata.value.languages[0]],
                avatarUrl: entity.metadata.value.media.avatar,
                avatarText: entity
                    .metadata.value.name[entity.metadata.value.languages[0]],
                avatarHexSource: entity.reference.entityId,
                rightText: DateFormat('MMMM dd')
                    .format(DateTime.parse(post.datePublished).toLocal()),
              )
            ]),
      ),
    );
  }

  onPostCardTap(
      BuildContext context, FeedPost post, EntityModel entity, int index) {
    Navigator.of(context).pushNamed("/entity/feed/post",
        arguments: FeedPostArgs(entity: entity, post: post, index: index));
  }
}
