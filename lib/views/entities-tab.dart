import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:dvote/dvote.dart';
// import 'package:vocdoni/views/entity.dart';
// import 'package:vocdoni/widgets/pageTitle.dart';
// import 'package:vocdoni/widgets/section.dart';

class EntitiesTab extends StatelessWidget {
  

  EntitiesTab();

  @override
  Widget build(ctx) {
    if (account.ents.length == 0) return buildNoEntities(ctx);

    return ListView.builder(
        itemCount: account.ents.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final ent = account.ents[index];
          return ent.entityMetadata == null
              ? buildEmptyMetadataCard(ctx, ent)
              : buildCard(ctx, ent);
        });
  }

  Widget buildEmptyMetadataCard(BuildContext ctx, Ent ent) {
    return BaseCard(children: [
      ListItem(
          mainText: ent.entityReference.entityId,
          avatarHexSource: ent.entityReference.entityId,
          isBold: true,
          onTap: () => onTapEntity(ctx, ent))
    ]);
  }

  Widget buildCard(BuildContext ctx, Ent ent) {
    final feedPostAmount = getFeedPostAmount(ent);
    return BaseCard(children: [
      buildName(ctx, ent),
      ListItem(
          mainText: "Feed",
          icon: FeatherIcons.rss,
          rightText: feedPostAmount.toString(),
          rightTextIsBadge: true,
          onTap: () {
            Navigator.pushNamed(ctx, "/entity/feed", arguments: ent);
          },
          disabled: feedPostAmount == 0),
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
        onTap: () => onTapEntity(ctx, ent));
  }

  buildParticipationItem(BuildContext ctx, Ent ent) {
    if (ent.processess == null) return Container();
    return ListItem(
        mainText: "Participation",
        icon: FeatherIcons.mail,
        rightText: ent.processess.length.toString(),
        rightTextIsBadge: true,
        onTap: () => onTapParticipation(ctx, ent),
        disabled: ent.processess.length == 0);
  }

  Widget buildNoEntities(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("No entities"),
    );
  }

  onTapEntity(BuildContext ctx, Ent ent) {
    Navigator.pushNamed(ctx, "/entity", arguments: ent);
  }

  onTapParticipation(BuildContext ctx, Ent ent) {
    Navigator.pushNamed(ctx, "/entity/participation", arguments: ent);
  }
}
