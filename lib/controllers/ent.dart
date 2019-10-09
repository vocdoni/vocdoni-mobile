import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/controllers/processModel.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

enum EntTags {ENTITY_METADATA, SUBSCRIBED }

class Ent extends StatesRebuilder {
  EntityReference entityReference;
  DataState entityMetadataDataState = DataState.UNKNOWN;
  EntityMetadata entityMetadata;
  Feed feed;
  List<ProcessModel> processess;
  String lang = "default";
  //bool entityMetadataUpdated = false;
  bool processessMetadataUpdated = false;
  bool feedUpdated = false;

  Ent(EntityReference entitySummary) {
    this.entityReference = entitySummary;
    syncLocal();
  }

  update() async {
    try {
      this.entityMetadata = await fetchEntityData(this.entityReference);
      entityMetadataDataState = DataState.GOOD;
      
    } catch (e) {
      entityMetadataDataState = DataState.ERROR;
    }
    if (hasState) rebuildStates([EntTags.ENTITY_METADATA]);

    try {
      await updateProcesses();
      processessMetadataUpdated = true;
    } catch (e) {
      debugPrint(e.toString());
      processessMetadataUpdated = false;
    }
    /*
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
    }*/
    try {
      this.feed = await fetchEntityNewsFeed(
          this.entityReference, this.entityMetadata, this.lang);
      feedUpdated = true;
    } catch (e) {
      feedUpdated = false;
    }
  }

  updateProcesses() async {
    // go over active processess
    // if Process exists, update
    // If Process does not exits, create new one and update

    final updatedProcessess =
        this.entityMetadata.votingProcesses.active.map((String processId) {
      ProcessModel p;
      //Get  Process if exist
      if (this.processess != null) {
        p = this.processess.firstWhere((ProcessModel process) {
          return process.processId == processId;
        }, orElse: () {
          return null;
        });
      }

      // Update
      if (p != null) {
        p.update();
        return p;
      } else {
        //Make new one and update
        final newProcess = new ProcessModel(
            processId: processId, entityReference: this.entityReference);
        newProcess.update();
        return newProcess;
      }
    }).toList();

    this.processess = updatedProcessess;
  }

  syncProcessess() {
    this.processess =
        this.entityMetadata.votingProcesses.active.map((String processId) {
      return new ProcessModel(
          processId: processId, entityReference: this.entityReference);
    }).toList();
  }

  save() async {
    if (this.entityMetadata != null)
      await entitiesBloc.add(this.entityMetadata, this.entityReference);
    if (this.processess != null) {
      for (ProcessModel process in this.processess) {
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
      //syncProcessess(this.entityMetadata, this.entityReference);
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
    if (hasState) rebuildStates([EntTags.ENTITY_METADATA]);

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

  /*//syncProcessess(EntityMetadata entityMetadata, EntityReference entitySummary) {
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
  }*/
}
