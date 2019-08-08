import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/settings.dart' show bootnodesUrl;
import 'package:dvote/dvote.dart';

// ////////////////////////////////////////////////////////////////////////////
// METHODS
// ////////////////////////////////////////////////////////////////////////////

Future<List<Gateway>> getBootNodes() async {
  try {
    List<Gateway> result = List<Gateway>();
    final strBootnodes = await http.read(bootnodesUrl);
    Map<String, dynamic> networkItems = jsonDecode(strBootnodes);
    networkItems.forEach((networkId, network) {
      if (!(network is List)) return;
      network.forEach((item) {
        if (!(item is Map)) return;
        Gateway gw = Gateway();
        gw.dvote = item["dvote"] ?? "";
        gw.web3 = item["web3"] ?? "";
        gw.publicKey = item["pubKey"] ?? "";
        gw.meta.addAll({"networkId": networkId ?? ""});
        result.add(gw);
      });
    });
    return result;
  } catch (err) {
    throw FetchError("The boot nodes cannot be loaded");
  }
}

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

Future<Entity> fetchEntityData(String resolverAddress, String entityId,
    String networkId, List<String> entryPoints) async {
  // Create a random cloned list
  var bootnodes = appStateBloc.current.bootnodes
      .where((gw) => gw.meta["networkId"] == networkId)
      .toList();
  bootnodes.shuffle();

  // Attempt for every node available
  for (Gateway node in bootnodes) {
    try {
      final Entity entity = await fetchEntity(
          entityId, resolverAddress, node.dvote, node.web3,
          networkId: networkId, entryPoints: entryPoints);

      return entity;
    } catch (err) {
      print(err);
      continue;
    }
  }
  throw FetchError("The entity's data cannot be fetched");
}

Future<String> fetchEntityNewsFeed(Entity entity, String lang) async {
  // Attempt for every node available
  if (!(entity is Entity))
    return null;
  else if (!(entity.newsFeed is Map<String, String>))
    return null;
  else if (!(entity.newsFeed[lang] is String)) return null;

  // Create a random cloned list
  var bootnodes = appStateBloc.current.bootnodes.skip(0).toList();
  bootnodes.shuffle();

  final String contentUri = entity.newsFeed[lang];

  // Attempt for every node available
  for (Gateway node in bootnodes) {
    try {
      ContentURI cUri = ContentURI(contentUri);
      final result = await fetchFileString(cUri, node.dvote);
      return result;
    } catch (err) {
      print(err);
      continue;
    }
  }
  throw FetchError("The news feed cannot be fetched");
}

// ////////////////////////////////////////////////////////////////////////////
// UTILITIES
// ////////////////////////////////////////////////////////////////////////////

class FetchError implements Exception {
  final String msg;
  const FetchError(this.msg);
  String toString() => 'FetchError: $msg';
}
