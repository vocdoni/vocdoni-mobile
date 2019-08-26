import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data/ent.dart';
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
    //List<Entity> entities = [];
/*
    if (appState == null ||
        identities == null ||
        identities[appState.selectedIdentity] == null ||
        identities[appState.selectedIdentity].peers.entities.length == 0)
        */
    // if (account.ents == 0) return buildNoEntities(ctx);

    //Identity account = identitiesBloc.getCurrentAccount();

    /*account.peers.entities.forEach((entitySummary) {
      for (Entity entity in entitiesBloc.value)
        if (entity.entityId == entitySummary.entityId) {
          entities.add(entity);
        }
    });*/

    if (account.ents.length == 0) return buildNoEntities(ctx);

    return ListView.builder(
        itemCount: account.ents.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final ent = account.ents[index];
          final feedPostAmount = getFeedPostAmount(ent);
          return BaseCard(children: [
            buildName(ctx, ent),
            ListItem(
                mainText: "Feed",
                icon: FeatherIcons.rss,
                rightText: feedPostAmount.toString(),
                rightTextIsBadge: true,
                onTap: () {
                  Navigator.pushNamed(ctx, "/entity/activity", arguments: ent);
                },
                disabled: feedPostAmount == 0),
            buildParticipationItem(ctx, ent),
          ]);
        });
  }

  int getFeedPostAmount(Ent ent) {
    //TODO Refactor NewsFeedBloc
    return 10;
  }

  Widget buildName(BuildContext ctx, Ent ent) {
    String title = ent.entityMetadata.name[ent.entityMetadata.languages[0]];
    return ListItem(
        mainTextTag: ent.entitySummary.entityId + title,
        mainText: title,
        avatarUrl: ent.entityMetadata.media.avatar,
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
