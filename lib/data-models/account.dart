import 'package:dvote/dvote.dart';
import 'package:vocdoni/data-models/entModel.dart';
import 'package:vocdoni/lib/singletons.dart';

class Account {
  List<EntModel> ents = new List<EntModel>();
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
          EntModel ent = new EntModel(entitySummary);
          this.ents.add(ent);
        }
    });
  }

  sync() {
    this.ents = this
        .identity
        .peers
        .entities
        .map((EntityReference entitySummary) => EntModel(entitySummary))
        .toList();
  }

  isSubscribed(EntityReference _entitySummary) {
    return identitiesBloc.isSubscribed(this.identity, _entitySummary);
  }

  subscribe(EntModel ent) async {
    await identitiesBloc.subscribeEntityToAccount(
        ent.entityReference, account.identity);
    this.ents.add(ent);
  }

  unsubscribe(EntityReference _entitySummary) async {
    await identitiesBloc.unsubscribeEntityFromAccount(
        _entitySummary, account.identity);
    int index = ents.indexWhere(
        (ent) => _entitySummary.entityId == ent.entityReference.entityId);
    if (index != -1) ents.removeAt(index);
  }

  getEnt(EntityReference entityReference) {
    for (EntModel ent in this.ents) {
      if (ent.entityReference.entityId == entityReference.entityId) return ent;
    }
    EntModel ent = new EntModel(entityReference);
    if (isSubscribed(entityReference) == false) this.subscribe(ent);
    return ent;
  }

  updateEnts() async {
    for (EntModel ent in this.ents) {
      await ent.update();
    }
  }
}
