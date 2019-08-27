import 'dart:convert';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

class Ent {
  EntityReference entitySummary;
  EntityMetadata entityMetadata;
  Feed feed;
  List<ProcessMetadata> processess;
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
      return e.meta[META_ENTITY_ID] == entitySummary.entityId;
    });

    if (index == -1) {
      this.entityMetadata = null;
    } else {
      this.entityMetadata = entitiesBloc.value[index];
    }
  }

  syncFeed(EntityReference _entitySummary, EntityMetadata _entityMetadata) {
    final feeds = newsFeedsBloc.value.where((f) {
      if (f.meta[META_ENTITY_ID] != _entitySummary.entityId)
        return false;
      else if (f.meta[META_LANGUAGE] != _entityMetadata.languages[0])
        return false;
      return true;
    }).toList();

    this.feed = feeds.length > 0 ? this.feed = feeds[0] : this.feed = null;
  }

  syncProcessess(EntityMetadata entityMetadata, EntityReference entitySummary) {
    
    final _processess = processesBloc.value.where((process) {
      //Process is listed as active
      bool isActive = entityMetadata.votingProcesses.active.indexOf(process.meta[META_PROCESS_ID])!=-1;
      //Process belongs to the org that created it.
      bool isFromEntity = process.meta[META_ENTITY_ID] == entitySummary.entityId;
      return isActive && isFromEntity;
    }).toList();

    entityMetadata.votingProcesses.active.forEach((processId) {

    });

    this.processess = _processess.length > 0 ? _processess : null;
  }
}
