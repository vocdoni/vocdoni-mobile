import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:dvote/dvote.dart';
// import 'package:vocdoni/views/entity.dart';
// import 'package:vocdoni/widgets/pageTitle.dart';
// import 'package:vocdoni/widgets/section.dart';

class EntitiesTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;

  EntitiesTab({this.appState, this.identities});

  @override
  Widget build(ctx) {
    List<Entity> entities = [];

    if (appState == null ||
        identities == null ||
        identities[appState.selectedIdentity] == null ||
        identities[appState.selectedIdentity].peers.entities.length == 0)
      return buildNoEntities(ctx);

    Identity account = identitiesBloc.getCurrentAccount();

    account.peers.entities.forEach((entitySummary) {
      for (Entity entity in entitiesBloc.value)
        if (entity.entityId == entitySummary.entityId) {
          entities.add(entity);
        }
    });

    if (entities.length == 0) return buildNoEntities(ctx);

    return ListView.builder(
        itemCount: entities.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final entity = entities[index];
          final feedPostAmount = getFeedPostAmount(entity);
          return BaseCard(children: [
            ListItem(
                mainText: entity.name[entity.languages[0]],
                avatarUrl: entity.media.avatar,
                onTap: () => onTapEntity(ctx, entity)),
            ListItem(
                mainText: "Feed",
                icon: FeatherIcons.rss,
                rightText: feedPostAmount.toString(),
                rightTextIsBadge: true,
                onTap: () {
                  Navigator.pushNamed(ctx, "/entity/activity",
                      arguments: entity);
                },
                disabled: feedPostAmount==0 ),
            ListItem(
                mainText: "Participation",
                icon: FeatherIcons.mail,
                rightText: entity.votingProcesses.active.length.toString(),
                rightTextIsBadge: true,
                onTap: () => onTapParticipation(ctx, entity),
                disabled: entity.votingProcesses.active.length == 0)
          ]);
        });
  }

  int getFeedPostAmount(Entity entity)
  {
    //TODO Refactor NewsFeedBloc
    return 10;
  }

  Widget buildNoEntities(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("No entities"),
    );
  }

  onTapEntity(BuildContext ctx, Entity entity) {
    Navigator.pushNamed(ctx, "/entity", arguments: entity);
  }

  onTapParticipation(BuildContext ctx, Entity entity) {
    Navigator.pushNamed(ctx, "/entity/participation", arguments: entity);
  }
}
