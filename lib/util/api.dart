import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/settings.dart' show bootnodesUrl;
import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode

// ////////////////////////////////////////////////////////////////////////////
// METHODS
// ////////////////////////////////////////////////////////////////////////////

Future<String> makeMnemonic() {
  return generateMnemonic(size: 192);
}

Future<String> privateKeyFromMnemonic(String mnemonic) {
  return mnemonicToPrivateKey(mnemonic);
}

Future<String> publicKeyFromMnemonic(String mnemonic) {
  return mnemonicToPublicKey(mnemonic);
}

Future<String> addressFromMnemonic(String mnemonic) {
  return mnemonicToAddress(mnemonic);
}

Future<EntityMetadata> fetchEntityData(EntityReference entityReference) async {
  if (!(entityReference is EntityReference)) return null;

  try {
    final gw = _selectRandomGatewayInfo();

    return fetchEntity(entityReference, gw.dvote, gw.web3, gatewayPublicKey: gw.publicKey);
  } catch (err) {
    if (!kReleaseMode) print(err);
    throw FetchError("The entity's data cannot be fetched");
  }
}

Future<String> fetchEntityNewsFeed(
    EntityMetadata entityMetadata, String lang) async {
  // Attempt for every node available
  if (!(entityMetadata is EntityMetadata))
    return null;
  else if (!(entityMetadata.newsFeed is Map<String, String>))
    return null;
  else if (!(entityMetadata.newsFeed[lang] is String)) return null;

  final gw = _selectRandomGatewayInfo();

  final String contentUri = entityMetadata.newsFeed[lang];

  // Attempt for every node available
  try {
    ContentURI cUri = ContentURI(contentUri);
    final result =
        await fetchFileString(cUri, gw.dvote, gatewayPublicKey: gw.publicKey);
    return result;
  } catch (err) {
    print(err);
    throw FetchError("The news feed cannot be fetched");
  }
}

// ////////////////////////////////////////////////////////////////////////////
// UTILITIES
// ////////////////////////////////////////////////////////////////////////////

class FetchError implements Exception {
  final String msg;
  const FetchError(this.msg);
  String toString() => 'FetchError: $msg';
}

GatewayInfo _selectRandomGatewayInfo() {
  if (appStateBloc.value == null || appStateBloc.value.bootnodes == null)
    return null;

  final gw = GatewayInfo();

  if (kReleaseMode) {
    // PROD
    int dvoteIdx =
        random.nextInt(appStateBloc.value.bootnodes.homestead.dvote.length);
    int web3Idx =
        random.nextInt(appStateBloc.value.bootnodes.homestead.web3.length);

    gw.dvote = appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].uri;
    gw.publicKey =
        appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].apis);
    gw.web3 = appStateBloc.value.bootnodes.homestead.web3[web3Idx].uri;
  } else {
    int dvoteIdx =
        random.nextInt(appStateBloc.value.bootnodes.goerli.dvote.length);
    int web3Idx =
        random.nextInt(appStateBloc.value.bootnodes.goerli.web3.length);

    gw.dvote = appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].uri;
    gw.publicKey = appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].apis);
    gw.web3 = appStateBloc.value.bootnodes.goerli.web3[web3Idx].uri;
  }
  return gw;
}
