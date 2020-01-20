import 'package:dvote/dvote.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/views/entity-info-page.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/card-loading.dart';
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
    globalAnalytics.trackPage("EntitiesTab");
  }

  @override
  Widget build(ctx) {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null)
      return buildNoEntities(ctx);
    else if (!currentAccount.entities.hasValue ||
        currentAccount.entities.value.length == 0) return buildNoEntities(ctx);

    // Rebuild if the pool changes (not the items)
    return Consumer<EntityPoolModel>(
      builder: (ctx, entityPool, _) => ListView.builder(
          itemCount: currentAccount.entities.value.length,
          itemBuilder: (BuildContext ctxt, int index) {
            final entity = currentAccount.entities.value[index];

            if (entity.metadata.hasValue)
              return buildCard(ctx, entity);
            else if (entity.metadata.isLoading) return CardLoading();
            return buildEmptyMetadataCard(ctx, entity.reference);
          }),
    );
  }

  Widget buildEmptyMetadataCard(
      BuildContext ctx, EntityReference entityReference) {
    return BaseCard(children: [
      ListItem(
          mainText: entityReference.entityId,
          avatarHexSource: entityReference.entityId,
          isBold: true,
          onTap: () => onTapEntity(ctx, entityReference))
    ]);
  }

  Widget buildCard(BuildContext ctx, EntityModel ent) {
    return BaseCard(children: [
      buildName(ctx, ent),
      buildFeedRow(ctx, ent),
      buildParticipationRow(ctx, ent),
    ]);
  }

  int getFeedPostCount(EntityModel ent) {
    if (!ent.feed.hasValue)
      return 0;
    else if (!ent.feed.value.feed.hasValue)
      return 0;
    else if (ent.feed.value.feed.value.items is List)
      return ent.feed.value.feed.value.items.length;
    return 0;
  }

  Widget buildName(BuildContext ctx, EntityModel entity) {
    String title =
        entity.metadata.value.name[entity.metadata.value.languages[0]];
    return ListItem(
        heroTag: entity.reference.entityId + title,
        mainText: title,
        avatarUrl: entity.metadata.value.media.avatar,
        avatarText: title,
        avatarHexSource: entity.reference.entityId,
        isBold: true,
        onTap: () => onTapEntity(ctx, entity.reference));
  }

  Widget buildParticipationRow(BuildContext ctx, EntityModel entity) {
    // Consume intermediate values, not present from the root context and rebuild if
    // the entity's process list changes
    return ChangeNotifierProvider.value(
      value: entity.processes,
      child: ListItem(
          mainText: "Participation",
          icon: FeatherIcons.mail,
          rightText: entity.processes.hasValue
              ? entity.processes.value.length.toString()
              : "0",
          rightTextIsBadge: true,
          onTap: () => onTapParticipation(ctx, entity),
          disabled:
              !entity.processes.hasValue || entity.processes.value.length == 0),
    );
  }

  Widget buildFeedRow(BuildContext ctx, EntityModel entity) {
    // Consume intermediate values, not present from the root context and rebuild if
    // the entity's news feed changes
    return ChangeNotifierProvider.value(
      value: entity.feed,
      child: Builder(builder: (ctx) {
        final feedPostAmount = getFeedPostCount(entity);
        return ListItem(
            mainText: "Feed",
            icon: FeatherIcons.rss,
            rightText: feedPostAmount.toString(),
            rightTextIsBadge: true,
            onTap: () => onTapFeed(ctx, entity),
            disabled: feedPostAmount == 0);
      }),
    );
  }

  Widget buildNoEntities(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("No entities"),
    );
  }

  onTapEntity(BuildContext ctx, EntityReference entityRef) {
    final route =
        MaterialPageRoute(builder: (context) => EntityInfoPage(entityRef));
    Navigator.push(ctx, route);
  }

  onTapParticipation(BuildContext ctx, EntityModel entity) {
    Navigator.pushNamed(ctx, "/entity/participation", arguments: entity);
  }

  onTapFeed(BuildContext ctx, EntityModel entity) {
    Navigator.pushNamed(ctx, "/entity/feed", arguments: entity);
  }
}
