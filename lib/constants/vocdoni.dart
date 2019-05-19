final List<String> networks = ["homestead", "ropsten", "vctestnet"];

/// Enumeration of ENS resolver text keys supported by DVoteJS
/// https://github.com/vocdoni/dvote-js/blob/master/src/dvote/entity-resolver.ts#L92

class TextRecordKeys {
  static const String NAME = "vnd.vocdoni.entity-name";
  static const String LANGUAGES = "vnd.vocdoni.languages";
  static const String JSON_METADATA_CONTENT_URI = "vnd.vocdoni.meta";
  static const String VOTING_CONTRACT_ADDRESS = "vnd.vocdoni.voting-contract";
  static const String GATEWAYS_UPDATE_CONFIG = "vnd.vocdoni.gateway-update";
  static const String ACTIVE_PROCESS_IDS = "vnd.vocdoni.process-ids.active";
  static const String ENDED_PROCESS_IDS = "vnd.vocdoni.process-ids.ended";
  static const String NEWS_FEED_URI_PREFIX = "vnd.vocdoni.news-feed.";
  static const String DESCRIPTION_PREFIX = "vnd.vocdoni.entity-description.";
  static const String AVATAR_CONTENT_URI = "vnd.vocdoni.avatar";
}

/// Enumeration of ENS resolver text list keys supported by DVoteJS
/// https://github.com/vocdoni/dvote-js/blob/master/src/dvote/entity-resolver.ts#L105

class TextListRecordKeys {
  static const String GATEWAY_BOOT_NODES = "vnd.vocdoni.gateway-boot-nodes";
  static const String BOOT_ENTITIES = "vnd.vocdoni.boot-entities";
  static const String FALLBACK_BOOTNODE_ENTITIES =
      "vnd.vocdoni.fallback-bootnodes-entities";
  static const String TRUSTED_ENTITIES = "vnd.vocdoni.trusted-entities";
  static const String CENSUS_SERVICES = "vnd.vocdoni.census-services";
  static const String CENSUS_SERVICE_SOURCE_ENTITIES =
      "vnd.vocdoni.census-service-source-entities";
  static const String CENSUS_IDS = "vnd.vocdoni.census-ids";
  static const String CENSUS_MANAGER_KEYS = "vnd.vocdoni.census-manager-keys";
  static const String RELAYS = "vnd.vocdoni.relays";
}
