import 'package:dvote/dvote.dart';

EntityReference makeEntityReference(
    {String entityId,
    String resolverAddress,
    String networkId,
    List<String> entryPoints}) {
  EntityReference summary = EntityReference();
  summary.entityId = entityId;
  summary.entryPoints.addAll(entryPoints ?? []);
  return summary;
}

GatewayInfo getInitialBootnode() {
  GatewayInfo node = new GatewayInfo();
  //node.mergeFromJson(bootNodeJson);
  node.web3 = 'https://gwdev1.vocdoni.net/web3';
  node.dvote = 'wss://gwdev1.vocdoni.net/dvote';
  //node.supportedApis = ["file", "vote", "census"];
  return node;
}
