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
      for (Entity entity in entitiesBloc.value)
        if (entity.meta['entityId'] == entitySummary.entityId) {
          Ent ent = new Ent(entitySummary);
          this.ents.add(ent);
        }
    });
  }

  sync() {
    this.ents.forEach((Ent ent) {
      ent.syncLocal();
    });
  }

  isSubscribed(EntitySummary _entitySummary) {
    return identitiesBloc.isSubscribed(this.identity, _entitySummary);
  }

  subscribe(Ent ent) async {
    await identitiesBloc.subscribeEntityToAccount(ent, account.identity);
    sync();
  }

  unsubscribe(EntitySummary _entitySummary) async {
    await identitiesBloc.unsubscribeEntityFromAccount(
        _entitySummary, account.identity);
  }
}

// Ent exist only on runtime. It is not stored as such
// Ent exists for the selected identity only
class Ent {
  EntitySummary entitySummary;
  Entity entityMetadata;
  Feed feed;
  List<ProcessMock> processess;
  String lang = "default";

  Ent(EntitySummary entitySummary) {
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

  syncEntityMetadata(EntitySummary entitySummary) {
    int index = entitiesBloc.value.indexWhere((e) {
      return e.meta['entityId'] == entitySummary.entityId;
    });

    if (index == -1) {
      this.entityMetadata = null;
    } else {
      this.entityMetadata = entitiesBloc.value[index];
    }
  }

  syncFeed(EntitySummary _entitySummary, Entity _entityMetadata) {
    final feeds = newsFeedsBloc.value.where((f) {
      if (f.meta["entityId"] != _entitySummary.entityId)
        return false;
      else if (f.meta["language"] != _entityMetadata.languages[0]) return false;
      return true;
    }).toList();

    this.feed = feeds.length > 0 ? this.feed = feeds[0] : this.feed = null;
  }

  syncProcessess(Entity entityMetadata, EntitySummary entitySummary) {
    final _processess = processesBloc.value.where((process) {
      return process.meta['entityId'] == entitySummary.entityId;
    }).toList();

    this.processess =
        _processess.length > 0 ? this.processess : this.processess = null;
  }
}

