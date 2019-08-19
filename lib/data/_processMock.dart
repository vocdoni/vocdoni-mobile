import "dart:convert";
import 'package:flutter/rendering.dart';

class ProcessMock {
  String version;
  String type;
  int startBlock;
  int numberOfBlocks;
  Census census;
  ProcessDetails details;
}

class Census {
  String id;
  String merkleRoot;
  List<String> messagingUris;
}

class ProcessDetails {
  String entityId;
  String encryptionPublicKey;
  Map<String, String> title;
  Map<String, String> description;
  String headerImage;
  List<Question> questions;

  ProcessDetails() {
    title = new Map();
    description = new Map();
  }
}

class Question {
  String type;
  Map<String, String> question;
  Map<String, String> description;
  List<VoteOption> voteOptions;

  Question() {
    question = new Map();
    description = new Map();
  }
}

class VoteOption {
  Map<String, String> title;
  int value;

  VoteOptions() {
    title = new Map();
  }
}

//PROCESSESS
ProcessMock parseProcess(String json) {
  try {
    ProcessMock result = ProcessMock();
    final mapProcess = jsonDecode(json);
    if (!(mapProcess is Map)) return null;

    if (mapProcess["version"] != null) result.version = mapProcess["version"];
    if (mapProcess["type"] != null) result.type = mapProcess["type"];
    if (mapProcess["startBlock"] != null)
      result.startBlock = mapProcess["startBlock"];
    if (mapProcess["numberOfBlocks"] != null)
      result.numberOfBlocks = mapProcess["numberOfBlocks"];

    dynamic mapCensus;
    Census censusResult = Census();
    if (mapProcess["census"] != null) mapCensus = mapProcess["census"];
    if (mapCensus["id"] != null) censusResult.id = mapCensus["id"];
    if (mapCensus["merkleRoot"] != null)
      censusResult.merkleRoot = mapCensus["merkleRoot"];
    if (mapCensus["messagingUris"] is List)
      mapCensus["messagingUris"].whereType<Map>().map((uri) {
        censusResult.messagingUris.add(uri);
      });

    result.census = censusResult;

    dynamic mapDetails;
    ProcessDetails detailsResult = new ProcessDetails();
    if (mapProcess["details"] != null) mapDetails = mapProcess["details"];
    if (mapDetails["entityId"] != null)
      detailsResult.entityId = mapDetails["entityId"];
    if (mapDetails["encryptionPublicKey"] != null)
      detailsResult.encryptionPublicKey = mapDetails["encryptionPublicKey"];
    if (mapDetails["headerImage"] != null)
      detailsResult.headerImage = mapDetails["headerImage"];
    if (mapDetails["title"] != null)
      detailsResult.title
          .addAll(mapDetails["title"].cast<String, String>() ?? {});
    if (mapDetails["description"] != null)
      detailsResult.description
          .addAll(mapDetails["description"].cast<String, String>() ?? {});

    dynamic mapQuestions;
    List<Question> questionsResults = new List<Question>();
    if (mapDetails["questions"] != null) mapQuestions = mapDetails["questions"];

    if (mapQuestions is List)
      mapQuestions.whereType<Map>().map((mapQuestion) {
        Question questionResult = new Question();

        if (mapQuestion["type"] != null)
          questionResult.type = mapQuestion["type"];

        if (mapQuestion["question"] != null)
          questionResult.question
              .addAll(mapQuestion["question"].cast<String, String>() ?? {});

        if (mapQuestion["description"] != null)
          questionResult.description
              .addAll(mapQuestion["description"].cast<String, String>() ?? {});

        dynamic mapVoteOptions;
        List<VoteOption> voteOptionsResults = new List<VoteOption>();
        if (mapQuestion["voteOptions"] != null)
          mapVoteOptions = mapQuestion["voteOptions"];

        if (mapVoteOptions is List)
          mapVoteOptions.whereType<Map>().map((mapVoteOption) {
            VoteOption voteOptionResult = new VoteOption();

            if (mapVoteOption["title"] != null)
              voteOptionResult.title = mapVoteOption["title"];

            if (mapVoteOption["value"] != null)
              voteOptionResult.value = mapVoteOption["value"];

            voteOptionsResults.add(voteOptionResult);
          });
        questionsResults.add(questionResult);
      });
      detailsResult.questions = questionsResults;
      result.details = detailsResult;

    return result;
  } catch (err) {
    throw FlutterError("The process could not be parsed");
  }
}
