import 'dart:convert';

import 'package:vocdoni/data/_processMock.dart';

import 'package:dvote/dvote.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

// Ent exist only on runtime. It is not stored as such
// Ent exists for the selected identity only
class Ent {
  EntitySummary entitySummary;
  Entity entityMetadata;
  Feed feed;
  List<ProcessMock> processess;

  Ent(EntitySummary _entitySummary) {
    entitySummary = _entitySummary;

    for (Entity _entityMetadata in entitiesBloc.value) {
      if (_entityMetadata.meta['entityId'] == _entitySummary.entityId) {
        this.entityMetadata = _entityMetadata;
        this.feed = makeFeed(_entitySummary, _entityMetadata);
        this.processess = makeProcessess(_entityMetadata);
      }
    }
  }

  refresh(String lang) async {
    this.entityMetadata = await fetchEntityData(entitySummary);
    final feedString = await fetchEntityNewsFeed(entityMetadata, lang);
    this.feed = Feed.fromJson(jsonDecode(feedString));
  }

  persist() {}

  Feed makeFeed(EntitySummary _entitySummary, Entity _entityMetadata) {
    final feeds = newsFeedsBloc.value.where((f) {
      if (f.meta["entityId"] != _entitySummary.entityId)
        return false;
      else if (f.meta["language"] != _entityMetadata.languages[0]) return false;
      return true;
    }).toList();

    return feeds.length>0?feeds[1]:null;

  }

  List<ProcessMock> makeProcessess(Entity entityMetadata) {
    return null;
  }
}

class Account {
  List<Ent> ents = new List<Ent>();
  Identity identity;
  List<String> languages = ['default'];

  Account() {
    this.identity = identitiesBloc.getCurrentAccount();
    this.identity.peers.entities.forEach((entitySummary) {
      for (Entity entity in entitiesBloc.value)
        if (entity.meta['entityId'] == entitySummary.entityId) {
          Ent ent = new Ent(entitySummary);
          if(ent.entityMetadata==null){
            throw("Ent has no metadata");
          }
          this.ents.add(ent);
        }
    });
  }

  isSubscribed(EntitySummary _entitySummary) {
    return identitiesBloc.isSubscribed(this.identity, _entitySummary);
  }
}
