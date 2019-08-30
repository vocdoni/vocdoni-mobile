import 'package:dvote/dvote.dart';

EntityReference makeEntityReference(
    {String entityId,
    String resolverAddress,
    List<String> entryPoints}) {
  EntityReference summary = EntityReference();
  summary.entityId = entityId;
  summary.entryPoints.addAll(entryPoints ?? []);
  return summary;
}