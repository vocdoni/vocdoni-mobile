import 'package:dvote/dvote.dart';
import 'package:dvote/util/parsers.dart';
import 'package:vocdoni/controllers/process.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

class Ent {
  EntityReference entityReference;
  EntityMetadata entityMetadata;
  Feed feed;
  List<Process> processess;
  String lang = "default";

  Ent(EntityReference entitySummary) {
    this.entityReference = entitySummary;
    syncLocal();
  }

  update() async {
    this.entityMetadata = await fetchEntityData(this.entityReference);

    //TOOD Not make Process directly.
    // - check activeProcess from entity
    // - make new Process if they don't exists locally
    // - call Process.update() on each of them
  
    final processessMetadata =
        await fetchProcessess(this.entityReference, this.entityMetadata);
    this.processess = processessMetadata.map((processMetadata) {
      return new Process(processMetadata);
    }).toList();
    this.feed = await fetchEntityNewsFeed(
        this.entityReference, this.entityMetadata, this.lang);
  }

  save() async {
    if (this.entityMetadata != null)
      await entitiesBloc.add(this.entityMetadata, this.entityReference);
    if (this.processess != null) {
      for (Process process in this.processess) {
        process.save();
      }
    }
    if (this.feed != null)
      await newsFeedsBloc.add(this.lang, this.feed, this.entityReference);
  }

  syncLocal() async {
    syncEntityMetadata(entityReference);
    if (this.entityMetadata == null) {
      this.feed = null;
      this.processess = null;
    } else {
      syncFeed(entityReference, this.entityMetadata);
      syncProcessess(this.entityMetadata, this.entityReference);
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
      /*
      //Process is listed as active
      bool isActive = entityMetadata.votingProcesses.active
              .indexOf(process.meta[META_PROCESS_ID]) !=
          -1;

          */
      //Process belongs to the org that created it.
      bool isFromEntity =
          process.meta[META_ENTITY_ID] == entitySummary.entityId;
      return isFromEntity;
    }).toList();

    final processessMetadata = _processess.length > 0 ? _processess : null;
    this.processess = processessMetadata.map((processMetadata) {
      return new Process(processMetadata);
    }).toList();
  }
}
