import 'package:dvote/dvote.dart';
import 'package:vocdoni/controllers/process.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

class Ent {
  EntityReference entityReference;
  EntityMetadata entityMetadata;
  Feed feed;
  List<Process> processess;
  String lang = "default";
  bool entityMetadataUpdated = false;
  bool processessMetadataUpdated = false;

  Ent(EntityReference entitySummary) {
    this.entityReference = entitySummary;
    syncLocal();
  }

  update() async {
    try {
      this.entityMetadata = await fetchEntityData(this.entityReference);
      entityMetadataUpdated = true;
    } catch (e) {
      entityMetadataUpdated = false;
      return;
    }

    //TOOD Should only create procees that does not exist locally
    // - check activeProcess from entity
    // - make new Process if they don't exists locally
    // - call Process.update() on each of them
    try {
      final processessMetadata =
          await fetchProcessess(this.entityReference, this.entityMetadata);
      this.processess = processessMetadata.map((processMetadata) {
        return new Process(processMetadata);
      }).toList();
      processessMetadataUpdated = true;
    } catch (e) {
      processessMetadataUpdated = false;
      this.processess = null;
    }

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
    final processessMetadata = processesBloc.value.where((process) {
      /*
      //Process is listed as active
      bool isActive = entityMetadata.votingProcesses.active
              .indexOf(process.meta[META_PROCESS_ID]) !=
          -1;

          */
      //Process belongs to the org that created it.

      return process.meta[META_ENTITY_ID] == entitySummary.entityId;
    }).toList();

    if (processessMetadata.length == 0)
      this.processess = null;
    else
      this.processess = processessMetadata.map((processMetadata) {
        final process = new Process(processMetadata);
        process.syncLocal();
        return process;
      }).toList();
  }
}
