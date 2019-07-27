import 'package:http/http.dart' as http;
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/settings.dart' show bootnodesUrl;
import 'package:dvote/dvote.dart';
// import 'package:vocdoni/util/random.dart';
// import 'package:vocdoni/constants/vocdoni.dart';

Future<String> getBootNodes() {
  return http.read(bootnodesUrl);
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
  final List<BootNode> bootnodes = List<BootNode>();
  bootnodes.addAll(
      appStateBloc.current.bootnodes.where((bn) => bn.networkId == networkId));
  bootnodes.shuffle();

  // Attempt for every node available
  for (BootNode node in bootnodes) {
    try {
      final Entity entity = await fetchEntity(
          entityId, resolverAddress, node.dvoteUri, node.ethereumUri,
          networkId: networkId, entryPoints: entryPoints);

      return entity;
    } catch (err) {
      print(err);
      continue;
    }
  }
  return null;
}

Future<String> fetchEntityNewsFeed(Entity org, String lang) async {
  // Create a random cloned list
  final List<BootNode> bootnodes = List<BootNode>();
  bootnodes.addAll(appStateBloc.current.bootnodes);
  // TODO: USE Network id
  // bootnodes.addAll(
  //     appStateBloc.current.bootnodes.where((bn) => bn.networkId == networkId));
  bootnodes.shuffle();


  if (!(org is Entity))
    return null;
  else if (!(org.newsFeed is Map<String, String>))
    return null;
  else if (!(org.newsFeed[lang] is String)) return null;

  final String contentUri = org.newsFeed[lang];

  // Attempt for every node available
  for (BootNode node in bootnodes) {
    try {
      ContentURI cUri = ContentURI(contentUri);
      final result = await fetchFileString(cUri, node.dvoteUri);
      return result;
    } catch (err) {
      print(err);
      continue;
    }
  }
  throw ("Could not connect to the network");
}
