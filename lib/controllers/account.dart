import 'package:dvote/dvote.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/util/singletons.dart';

class Account {
  List<Ent> ents = new List<Ent>();
  Identity identity;
  List<String> languages = [];
  String networkId;

  Account() {
    languages = ['default'];
    networkId = 'goerli';

    init();
  }

  init() {
    this.identity = identitiesBloc.getCurrentIdentity();
    this.identity.peers.entities.forEach((entitySummary) {
      for (EntityMetadata entity in entitiesBloc.value)
        if (entity.meta['entityId'] == entitySummary.entityId) {
          Ent ent = new Ent(entitySummary);
          this.ents.add(ent);
        }
    });
  }

  sync() {
    this.ents = new List<Ent>();
    this.identity.peers.entities.forEach((EntityReference entitySummary) {
      ents.add(Ent(entitySummary));
    });
  }

  isSubscribed(EntityReference _entitySummary) {
    return identitiesBloc.isSubscribed(this.identity, _entitySummary);
  }

  subscribe(Ent ent) async {
    await identitiesBloc.subscribeEntityToAccount(
        ent.entityReference, account.identity);
    this.ents.add(ent);

    await ent.save();

    sync();
  }

  unsubscribe(EntityReference _entitySummary) async {
    await identitiesBloc.unsubscribeEntityFromAccount(
        _entitySummary, account.identity);
    int index = ents.indexWhere(
        (ent) => _entitySummary.entityId == ent.entityReference.entityId);
    if (index != -1) ents.removeAt(index);
  }
}
