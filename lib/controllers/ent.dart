import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/controllers/processModel.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum EntTags { ENTITY_METADATA, ACTIONS }

class Ent extends StatesRebuilder {
  EntityReference entityReference;
  DataState entityMetadataDataState = DataState.UNKNOWN;
  EntityMetadata entityMetadata;

  EntityMetadata_Action registerAction;
  DataState regiserActionDataState = DataState.UNKNOWN;
  bool isRegistered;
  List<EntityMetadata_Action> visibleActions;
  DataState visibleActionsDataState = DataState.UNKNOWN;

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

    updateVisibleActions();

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

  Future<void> updateVisibleActions() async {
    final List<EntityMetadata_Action> actionsToDisplay = [];
    EntityMetadata_Action registerAction;

    if (this.entityMetadata == null) return;

    this.visibleActionsDataState = DataState.CHECKING;
    if (hasState) rebuildStates([EntTags.ACTIONS]);

    for (EntityMetadata_Action action in this.entityMetadata.actions) {
      if (action.register == true) {
        if (registerAction != null)
          continue; //only one registerAction is supported
        registerAction = action;

        this.regiserActionDataState = DataState.CHECKING;
        bool isRegistered =
            await isActionVisible(action, this.entityReference.entityId);

        this.regiserActionDataState = DataState.GOOD;
        this.registerAction = registerAction;
        this.isRegistered = isRegistered;
        if (hasState) rebuildStates([EntTags.ACTIONS]);
      } else {
        if (await isActionVisible(action, this.entityReference.entityId)) {
          actionsToDisplay.add(action);
        }
      }
    }

    this.visibleActionsDataState = DataState.GOOD;
    this.visibleActions = actionsToDisplay;
    if (hasState) rebuildStates([EntTags.ACTIONS]);
  }

  Future<bool> isActionVisible(
      EntityMetadata_Action action, String entityId) async {
    if (action.visible == "true") return true;
    if (action.visible == null || action.visible == "false") return false;

    String publicKey = account.identity.identityId;
    int timestamp = new DateTime.now().millisecondsSinceEpoch;

    // TODO: Get the private key to sign appropriately
    final privateKey = "";
    debugPrint(
        "TODO: Retrieve the private key to sign the action visibility request");

    try {
      Map payload = {
        "type": action.type,
        'publicKey': publicKey,
        "entityId": entityId,
        "timestamp": timestamp,
        "signature": ""
      };

      if (privateKey != "") {
        payload["signature"] = await signString(
            jsonEncode({"timestamp": timestamp.toString()}), privateKey);
      } else {
        payload["signature"] = "0x"; // TODO: TEMP
      }

      Map<String, String> headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

      var response = await http.post(action.visible,
          body: jsonEncode(payload), headers: headers);
      if (response.statusCode != 200 || !(response.body is String))
        return false;
      final body = jsonDecode(response.body);
      if (body is Map && body["visible"] == true) return true;
    } catch (err) {
      return false;
    }

    return false;
  }
}
