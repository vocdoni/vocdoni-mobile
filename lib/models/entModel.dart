import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/data/data-state.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum EntTags { ENTITY_METADATA, ACTIONS, FEED, PROCESSES }

class EntModel extends StatesRebuilder {
  EntityReference entityReference;
  //final DataState entityMetadataDataState = DataState();
  final DataState<EntityMetadata> entityMetadata = DataState();

  final DataState<List<EntityMetadata_Action>> visibleActions = DataState();
  final DataState<EntityMetadata_Action> registerAction = DataState();
  final DataState<bool> isRegistered = DataState();

  final DataState<Feed> feed = DataState();

  final DataState<List<ProcessModel>> processes = DataState();
  String lang = "default";
  //final DataState processesDataState = DataState();

  EntModel(EntityReference entitySummary) {
    this.entityReference = entitySummary;
    syncLocal();
  }

  syncLocal() async {
    syncEntityMetadata(entityReference);

    if (this.entityMetadata.isValid) {
      syncFeed();
      syncProcesses();
    }
  }

  update() async {
    syncLocal();

    updateVisibleActions();
    updateFeed();
    updateProcesses();
  }

  updateEntityMetadata() async {
    try {
      this.entityMetadata.toBootingOrRefreshing();
      if (hasState) rebuildStates([EntTags.ENTITY_METADATA]);
      this.entityMetadata.value = await fetchEntityData(this.entityReference);
    } catch (e) {
      this.entityMetadata.toErrorOrFaulty("Unable to update entityMetadata");
    }

    saveMetadata();
    if (hasState) rebuildStates([EntTags.ENTITY_METADATA]);
  }

  updateFeed() async {
    this.feed.toBootingOrRefreshing();
    if (hasState) rebuildStates([EntTags.FEED]);

    Feed newFeed = await fetchEntityNewsFeed(
        this.entityReference, this.entityMetadata.value, this.lang);
    if (newFeed == null)
      this.feed.toErrorOrFaulty("Unable to fetch feed");
    else
      this.feed.value = newFeed;

    await saveFeed();

    if (hasState) rebuildStates([EntTags.FEED]);
  }

  syncProcesses() {
    this.processes.value = this
        .entityMetadata
        .value
        .votingProcesses
        .active
        .map((String processId) {
      return new ProcessModel(
          processId: processId, entityReference: this.entityReference);
    }).toList();
    if (hasState) rebuildStates([EntTags.PROCESSES]);
  }

  updateProcesses() async {
    this.processes.toBootingOrRefreshing();
    if (hasState) rebuildStates([EntTags.PROCESSES]);
    if (this.processes.isNotValid) syncProcesses();
    for (ProcessModel process in this.processes.value) {
      await process.update();
    }

    this.processes.value = this.processes.value;
    await saveProcesses();
    if (hasState) rebuildStates([EntTags.PROCESSES]);
  }

  ProcessModel getProcess(processId) {
    for (var process in this.processes.value) {
      if (process.processId == processId) return process;
    }
    return null;
  }

  saveMetadata() async {
    if (this.entityMetadata.isValid)
      await entitiesBloc.add(this.entityMetadata.value, this.entityReference);
  }

  saveFeed() async {
    if (this.feed.isValid)
      await newsFeedsBloc.add(this.lang, this.feed.value, this.entityReference);
  }

  saveProcesses() async {
    if (this.processes.isValid) {
      for (ProcessModel process in this.processes.value) {
        await process.save();
      }
    }
  }

  syncEntityMetadata(EntityReference entitySummary) {
    int index = entitiesBloc.value.indexWhere((e) {
      return e.meta[META_ENTITY_ID] == entitySummary.entityId;
    });

    if (index == -1) {
      this.entityMetadata.toUnknown();
    } else {
      this.entityMetadata.value = entitiesBloc.value[index];
    }
    if (hasState) rebuildStates([EntTags.ENTITY_METADATA]);
  }

  syncFeed() {
    final newFeed = newsFeedsBloc.value.firstWhere((f) {
      bool isFromEntity =
          f.meta[META_ENTITY_ID] != this.entityReference.entityId;
      bool isSameLanguage =
          f.meta[META_LANGUAGE] != this.entityMetadata.value.languages[0];
      return isFromEntity && isSameLanguage;
    }, orElse: () => null);

    if (newFeed == null)
      this.feed.toUnknown();
    else
      this.feed.value = newFeed;
    if (hasState) rebuildStates([EntTags.FEED]);
  }

  Future<void> updateVisibleActions() async {
    final List<EntityMetadata_Action> actionsToDisplay = [];
    EntityMetadata_Action registerAction;

    if (this.entityMetadata.isNotValid) return;

    this.visibleActions.toBootingOrRefreshing();
    if (hasState) rebuildStates([EntTags.ACTIONS]);

    for (EntityMetadata_Action action in this.entityMetadata.value.actions) {
      if (action.register == true) {
        if (registerAction != null)
          continue; //only one registerAction is supported

        this.registerAction.value = registerAction;

        this.isRegistered.value =
            await isActionVisible(action, this.entityReference.entityId);

        if (hasState) rebuildStates([EntTags.ACTIONS]);
      }
    }

    this.visibleActions.value = actionsToDisplay;
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
