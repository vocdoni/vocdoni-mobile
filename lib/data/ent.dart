import 'dart:convert';

import 'package:vocdoni/data/_processMock.dart';

import 'package:dvote/dvote.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

class Account {
  List<Ent> ents = new List<Ent>();
  Identity identity;
  List<String> languages = ['default'];

  Account() {
    init();
  }

  init() {
    this.identity = identitiesBloc.getCurrentAccount();
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
    await identitiesBloc.subscribeEntityToAccount(ent, account.identity);
    this.ents.add(ent);
    sync();
  }

  unsubscribe(EntityReference _entitySummary) async {
    await identitiesBloc.unsubscribeEntityFromAccount(
        _entitySummary, account.identity);
    int index = ents.indexWhere((ent) {
      _entitySummary.entityId = ent.entitySummary.entityId;
    });
    if (index != -1) ents.removeAt(index);
  }
}

// Ent exist only on runtime. It is not stored as such
// Ent exists for the selected identity only
class Ent {
  EntityReference entitySummary;
  EntityMetadata entityMetadata;
  Feed feed;
  List<ProcessMock> processess;
  String lang = "default";

  Ent(EntityReference entitySummary) {
    this.entitySummary = entitySummary;
    syncLocal();
  }

  update() async {
    this.entityMetadata = await fetchEntityData(entitySummary);
    final feedString =
        await fetchEntityNewsFeed(this.entityMetadata, this.lang);
    this.feed = Feed.fromJson(jsonDecode(feedString));
  }

  syncLocal() async {
    syncEntityMetadata(entitySummary);
    if (this.entityMetadata == null) {
      this.feed = null;
      this.processess = null;
    } else {
      syncFeed(entitySummary, this.entityMetadata);
      syncProcessess(this.entityMetadata, this.entitySummary);
    }
  }

  syncEntityMetadata(EntityReference entitySummary) {
    int index = entitiesBloc.value.indexWhere((e) {
      return e.meta['entityId'] == entitySummary.entityId;
    });

    if (index == -1) {
      this.entityMetadata = null;
    } else {
      this.entityMetadata = entitiesBloc.value[index];
    }
  }

  syncFeed(EntityReference _entitySummary, EntityMetadata _entityMetadata) {
    final feeds = newsFeedsBloc.value.where((f) {
      if (f.meta["entityId"] != _entitySummary.entityId)
        return false;
      else if (f.meta["language"] != _entityMetadata.languages[0]) return false;
      return true;
    }).toList();

    this.feed = feeds.length > 0 ? this.feed = feeds[0] : this.feed = null;
  }

  syncProcessess(EntityMetadata entityMetadata, EntityReference entitySummary) {
    final _processess = processesBloc.value.where((process) {
      return process.meta['entityId'] == entitySummary.entityId;
    }).toList();

    this.processess = _processess.length > 0 ? _processess : null;
  }
}
