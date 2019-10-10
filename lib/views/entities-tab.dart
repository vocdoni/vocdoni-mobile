import 'package:dvote/models/dart/entity.pbserver.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/controllers/processModel.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';

class EntitiesTab extends StatefulWidget {
  EntitiesTab();

  @override
  _EntitiesTabState createState() => _EntitiesTabState();
}

class _EntitiesTabState extends State<EntitiesTab> {
  @override
  void initState() {
    super.initState();
    analytics.trackPage(pageId: "EntitiesTab");
  }

  @override
  Widget build(ctx) {
    if (account.ents.length == 0) return buildNoEntities(ctx);

    return ListView.builder(
        itemCount: account.ents.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final ent = account.ents[index];

          return StateBuilder(
              viewModels: [ent],
              tag: EntTags.ENTITY_METADATA,
              builder: (ctx, tagId) {
                return ent.entityMetadataDataState == DataState.GOOD
                    ? buildCard(ctx, ent)
                    : buildEmptyMetadataCard(ctx, ent.entityReference);
              });
        });
  }

  Widget buildEmptyMetadataCard(BuildContext ctx, EntityReference entityReference) {
    return BaseCard(children: [
      ListItem(
          mainText: entityReference.entityId,
          avatarHexSource: entityReference.entityId,
          isBold: true,
          onTap: () => onTapEntity(ctx, entityReference))
    ]);
  }

  Widget buildCard(BuildContext ctx, Ent ent) {
    return BaseCard(children: [
      buildName(ctx, ent),
      buildFeedItem(ctx, ent),
      buildParticipationItem(ctx, ent),
    ]);
  }

  int getFeedPostAmount(Ent ent) {
    return ent.feed == null ? 0 : ent.feed.items.length;
  }

  Widget buildName(BuildContext ctx, Ent ent) {
    String title = ent.entityMetadata.name[ent.entityMetadata.languages[0]];
    return ListItem(
        mainTextTag: ent.entityReference.entityId + title,
        mainText: title,
        avatarUrl: ent.entityMetadata.media.avatar,
        avatarText: title,
        avatarHexSource: ent.entityReference.entityId,
        isBold: true,
        onTap: () => onTapEntity(ctx, ent.entityReference));
  }

  buildParticipationItem(BuildContext ctx, Ent ent) {
    if (ent.processess == null) return Container();
    return ListItem(
        mainText: "Participation",
        icon: FeatherIcons.mail,
        rightText: ent.processess.length.toString(),
        rightTextIsBadge: true,
        onTap: () => onTapParticipation(ctx, ent.entityReference),
        disabled: ent.processess.length == 0);
  }

  Widget buildFeedItem(BuildContext ctx, Ent ent) {
    return StateBuilder(
        viewModels: [ent],
        tag: EntTags.FEED,
        builder: (ctx, tagId) {
          final feedPostAmount = getFeedPostAmount(ent);
          return ListItem(
              mainText: "Feed",
              icon: FeatherIcons.rss,
              rightText: feedPostAmount.toString(),
              rightTextIsBadge: true,
              onTap: () {
                Navigator.pushNamed(ctx, "/entity/feed", arguments: ent);
              },
              disabled: feedPostAmount == 0);
        });
  }

  Widget buildNoEntities(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("No entities"),
    );
  }

  onTapEntity(BuildContext ctx, EntityReference entityReference) {
    Navigator.pushNamed(ctx, "/entity", arguments: entityReference);
  }

  onTapParticipation(BuildContext ctx, EntityReference entityReference) {
    Navigator.pushNamed(ctx, "/entity/participation", arguments: entityReference);
  }
}
