import 'dart:developer';
import 'package:vocdoni/lib/singletons.dart';
import 'net.dart';

Future<void> restorePersistence() {
  // READ PERSISTED DATA (protobuf)
  return Future.wait(<Future>[
    globalBootnodesPersistence.read(),
    globalIdentitiesPersistence.readAll(),
    globalEntitiesPersistence.readAll(),
    globalProcessesPersistence.readAll(),
    globalFeedPersistence.readAll(),
  ]);
}

Future<void> restoreDataPools() {
  // POPULATE THE MODEL POOLS (Read into memory)
  return Future.wait([
    // NOTE: Read's should be done first on the models that
    // don't depend on others to be restored
    globalProcessPool.readFromStorage(),
    globalFeedPool.readFromStorage(),
    globalAppState.readFromStorage(),
  ])
      .then((_) => globalEntityPool.readFromStorage())
      .then((_) => globalAccountPool.readFromStorage());
}

Future<void> startNetworking() {
  // Try to fetch bootnodes from the well-known URI

  return AppNetworking.init(forceReload: true).then((_) {
    if (!AppNetworking.isReady)
      throw Exception("No DVote Gateway is available");
  }).catchError((err) {
    log("[App] Network initialization failed: $err");
    log("[App] Trying to use the local gateway cache");

    // Retry with the existing cached gateways
    return AppNetworking.useFromGatewayInfo(globalAppState.bootnodeInfo.value);
  });
}
