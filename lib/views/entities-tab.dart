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

    int selectedIdentity = appState.selectedIdentity;
    entities = identities[selectedIdentity].peers.entities.map((e) {
      return entitiesBloc.current
          .firstWhere((entity) => entity.entityId == e.entityId);
    }).toList();
    if (entities.length == 0) return buildNoEntities(ctx);

    return ListView.builder(
        itemCount: entities.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final entity = entities[index];
          return BaseCard(children: [
            ListItem(
                mainText: entity.name[entity.languages[0]],
                avatarUrl: entity.media.avatar,
                onTap: () => onTapEntity(ctx, entity)),
            ListItem(
                mainText: "Feed",
                icon: FeatherIcons.rss,
                rightText: entity.newsFeed.entries.length.toString(),
                rightTextIsBadge: true,
                onTap: () => onTapEntity(ctx, entity),
                disabled: entity.newsFeed.entries.length == 0),
            ListItem(
                mainText: "Participation",
                icon: FeatherIcons.mail,
                rightText: entity.votingProcesses.active.length.toString(),
                rightTextIsBadge: true,
                onTap: () => onTapEntity(ctx, entity),
                disabled: entity.votingProcesses.active.length == 0)
          ]);
        });
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
}
