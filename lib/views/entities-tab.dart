import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
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
    });
    if (entities.length == 0) return buildNoEntities(ctx);

    return ListView.builder(
        itemCount: entities.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final entity = entities[index];
          return ListItem(
              text: entity.name[entity.languages[0]],
              onTap: () => onTapEntity(ctx, entity));
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
