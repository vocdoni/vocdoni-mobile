import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/lib/value-state.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/api.dart';
import 'package:vocdoni/lib/singletons.dart';
import "package:vocdoni/constants/meta-keys.dart";
import 'dart:convert';
import 'package:http/http.dart' as http;

enum EntityStateTags { ENTITY_METADATA, ACTIONS, FEED, PROCESSES }

class EntityModel extends StatesRebuilder {
  final EntityReference entityReference;
  final ValueState<EntityMetadata> entityMetadata = ValueState();

  final ValueState<List<EntityMetadata_Action>> visibleActions = ValueState();
  final ValueState<EntityMetadata_Action> registerAction = ValueState();
  final ValueState<bool> isRegistered = ValueState();

  final ValueState<Feed> feed = ValueState();

  final ValueState<List<ProcessModel>> processes = ValueState();
  String lang = "default";

  DateTime lastUpdated;


  updateEntityMetadata() async {
    try {
      this.entityMetadata.setToLoading();
      if (hasState) rebuildStates([EntityStateTags.ENTITY_METADATA]);
      this.entityMetadata.setValue(await fetchEntityData(this.entityReference));
    } catch (e) {
      this
          .entityMetadata
          .setError("Unable to update entityMetadata", keepPreviousValue: true);
    }

    saveMetadata();
    if (hasState) rebuildStates([EntityStateTags.ENTITY_METADATA]);
  }

  updateFeed() async {
    this.feed.setToLoading();
    if (hasState) rebuildStates([EntityStateTags.FEED]);

    try {
      this.feed.setValue(await fetchEntityNewsFeed(
          this.entityReference, this.entityMetadata.value, this.lang));
    } catch (error) {
      this.feed.setError("Unable to fetch the news feed");
    }

    await saveFeed();

    if (hasState) rebuildStates([EntityStateTags.FEED]);
  }

  syncProcesses() {
    if (!this.entityMetadata.hasValue) {
      this.processes.setError("The entity metadata is not available.");
      return;
    }
    this.processes.setValue([]);

    this
        .entityMetadata
        .value
        .votingProcesses
        .active
        .forEach((String processId) {
      ProcessModel process = ProcessModel(
          processId: processId, entityReference: this.entityReference);
      this.processes.value.add(process);
    });

    if (hasState) rebuildStates([EntityStateTags.PROCESSES]);
  }

  updateProcesses() async {
    if (!this.processes.hasValue) return;

    this.processes.setToLoading();
    if (hasState) rebuildStates([EntityStateTags.PROCESSES]);

    final procs = this.processes.value;
    for (ProcessModel process in procs) {
      await process.update();
    }

    this.processes.setValue(procs);
    await saveProcesses();
    if (hasState) rebuildStates([EntityStateTags.PROCESSES]);
  }

  ProcessModel getProcess(processId) {
    if (!this.processes.hasValue) return null;

    for (var process in this.processes.value) {
      if (process.processId == processId) return process;
    }
    return null;
  }

  saveMetadata() async {
    if (this.entityMetadata.hasValue)
      await entitiesBloc.add(this.entityMetadata.value, this.entityReference);
  }

  saveFeed() async {
    if (this.feed.hasValue)
      await newsFeedsBloc.add(this.lang, this.feed.value, this.entityReference);
  }

  saveProcesses() async {
    if (this.processes.hasValue) {
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
      this.entityMetadata.setError("Entity not found");
    } else {
      this.entityMetadata.setValue(entitiesBloc.value[index]);
    }
    if (hasState) rebuildStates([EntityStateTags.ENTITY_METADATA]);
  }

  syncFeed() {
    final newFeed = newsFeedsBloc.value.firstWhere((f) {
      bool isFromEntity =
          f.meta[META_ENTITY_ID] == this.entityReference.entityId;
      bool isSameLanguage =
          f.meta[META_LANGUAGE] == this.entityMetadata.value.languages[0];
      return isFromEntity && isSameLanguage;
    }, orElse: () => null);

    if (newFeed == null)
      this.feed.setError("News feed not found");
    else
      this.feed.setValue(newFeed);
    if (hasState) rebuildStates([EntityStateTags.FEED]);
  }

  Future<void> updateVisibleActions() async {
    final List<EntityMetadata_Action> actionsToDisplay = [];

    if (!this.entityMetadata.hasValue) return;

    this.visibleActions.setToLoading();
    if (hasState) rebuildStates([EntityStateTags.ACTIONS]);

    for (EntityMetadata_Action action in this.entityMetadata.value.actions) {
      if (action.register == true) {
        if (this.registerAction.value != null)
          continue; //only one registerAction is supported

        this.registerAction.setValue(action);
        this.isRegistered.setValue(
            await isActionVisible(action, this.entityReference.entityId));

        if (hasState) rebuildStates([EntityStateTags.ACTIONS]);
      } else {
        bool isVisible =
            await isActionVisible(action, this.entityReference.entityId);
        if (isVisible) actionsToDisplay.add(action);
      }
    }

    this.visibleActions.setValue(actionsToDisplay);
    if (hasState) rebuildStates([EntityStateTags.ACTIONS]);
  }

  Future<bool> isActionVisible(
      EntityMetadata_Action action, String entityId) async {
    if (action.visible == "true")
      return true;
    else if (action.visible == null || action.visible == "false") return false;

    // ELSE => the `visible` field is a URL

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
