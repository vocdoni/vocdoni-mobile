import 'package:dvote/dvote.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';

class Account {
  List<EntityModel> entities = new List<EntityModel>();
  Identity identity;
  List<String> languages = [];

  Account() {
    languages = ['default'];
    init();
  }

  init() {
    this.identity = identitiesBloc.getCurrentIdentity();
    this.identity.peers.entities.forEach((entitySummary) {
      for (EntityMetadata entity in entitiesBloc.value)
        if (entity.meta['entityId'] == entitySummary.entityId) {
          EntityModel ent = new EntityModel(entitySummary);
          this.entities.add(ent);
        }
    });
  }

  sync() {
    this.entities = this
        .identity
        .peers
        .entities
        .map((EntityReference entitySummary) => EntityModel(entitySummary))
        .toList();
  }

  bool isSubscribed(EntityReference _entitySummary) {
    return identitiesBloc.isSubscribed(this.identity, _entitySummary);
  }

  subscribe(EntityModel ent) async {
    await identitiesBloc.subscribeEntityToAccount(
        ent.entityReference, account.identity);
    this.entities.add(ent);
  }

  unsubscribe(EntityReference _entitySummary) async {
    await identitiesBloc.unsubscribeEntityFromAccount(
        _entitySummary, account.identity);
    int index = entities.indexWhere(
        (ent) => _entitySummary.entityId == ent.entityReference.entityId);
    if (index != -1) entities.removeAt(index);
  }

  findEntity(EntityReference entityReference) {
    for (EntityModel ent in this.entities) {
      if (ent.entityReference.entityId == entityReference.entityId) return ent;
    }
    EntityModel ent = new EntityModel(entityReference);
    return ent;
  }

  updateEntities() async {
    for (EntityModel ent in this.entities) {
      await ent.update();
    }
  }
}
