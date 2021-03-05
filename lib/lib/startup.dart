import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/logger.dart';
import 'net.dart';

Future<void> restorePersistence() {
  // READ PERSISTED DATA (protobuf)
  return Future.wait(<Future>[
    Globals.bootnodesPersistence.read(),
    Globals.identitiesPersistence.readAll(),
    Globals.entitiesPersistence.readAll(),
    Globals.processesPersistence.readAll(),
    Globals.feedPersistence.readAll(),
    Globals.settingsPersistence.read(),
    logger.init(),
  ]);
}

Future<void> restoreDataPools() {
  // POPULATE THE MODEL POOLS (Read into memory)
  return Future.wait([
    // NOTE: Read's should be done first on the models that
    // don't depend on others to be restored
    Globals.appState.readFromStorage(),
    Globals.processPool.readFromStorage(),
    Globals.feedPool.readFromStorage(),
  ])
      .then((_) => Globals.entityPool.readFromStorage())
      .then((_) => Globals.accountPool.readFromStorage());
}

Future<void> startNetworking() {
  // Try to fetch bootnodes from the well-known URI
  return AppNetworking.init(forceReload: true).then((_) {
    if (!AppNetworking.dvoteIsReady())
      throw Exception("No DVote Gateway is available");
  }).catchError((err) {
    logger.log("[App] Network initialization failed: $err");
    logger.log("[App] Trying to use the local gateway cache");

    // Retry with the existing cached gateways
    return AppNetworking.useFromGatewayInfo(
        Globals.appState.bootnodeInfo.value);
  });
}
