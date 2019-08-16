import "dart:convert";
import 'package:flutter/rendering.dart';

class ProcessMock {
  String version;
  String type;
  int startBlock;
  int numberOfBlocks;
  Census census;
}

class Census {
  String id;
  String merkleRoot;
  List<String> messagingUris;
}

class ProcessDetails {
  String entityId;
  String encryptionPublicKey;
  MultilanguageString title;
  MultilanguageString description;
  String headerImage;
  List<Question> questions;
}

class MultilanguageString {
  String def;
  String en;
  String ca;
}

class Question {
  String type;
  MultilanguageString question;
  MultilanguageString description;
  List<VoteOption> voteOptions;
}

class VoteOption {
  MultilanguageString title;
  int value;
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

    return result;
  } catch (err) {
    throw FlutterError("The process could not be parsed");
  }
}
