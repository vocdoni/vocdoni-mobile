import 'package:dvote/dvote.dart';

EntitySummary makeEntitySummary({String entityId, String resolverAddress,
    String networkId, List<Gateway> entryPoints}) {
  EntitySummary summary = EntitySummary();
  summary.entityId = entityId;
  summary.resolverAddress = resolverAddress;
  summary.networkId = networkId;
  summary.entryPoints.addAll(entryPoints ?? []);
  return summary;
}
