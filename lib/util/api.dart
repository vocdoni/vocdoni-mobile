import 'package:http/http.dart' as http;
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/urls.dart' show bootnodesUrl;
import 'package:dvote/dvote.dart';
// import 'package:vocdoni/util/random.dart';
// import 'package:vocdoni/constants/vocdoni.dart';
export 'package:dvote/dvote.dart' show Entity, ContentURI;

Future<String> getBootNodes() {
  return http.read(bootnodesUrl);
}

Future<String> generateMnemonic() {
  return Dvote.generateMnemonic(size: 192);
}

Future<String> mnemonicToPrivateKey(String mnemonic) {
  return Dvote.mnemonicToPrivateKey(mnemonic);
}

Future<String> mnemonicToPublicKey(String mnemonic) {
  return Dvote.mnemonicToPublicKey(mnemonic);
}

Future<String> mnemonicToAddress(String mnemonic) {
  return Dvote.mnemonicToAddress(mnemonic);
}

Future<Entity> fetchEntityData(String resolverAddress, String entityId,
    String networkId, List<String> entryPoints) async {
  // Create a random cloned list
  final List<BootNode> bootnodes = List<BootNode>();
  bootnodes.addAll(appStateBloc.current.bootnodes);
  bootnodes.shuffle();

  // Attempt for every node available
  for (BootNode node in bootnodes) {
    try {
      final Entity entity = await fetchEntity(
        entityId,
        resolverAddress,
        node.dvoteUri,
        node.ethereumUri,
        networkId: "1234",
        entryPoints: entryPoints
      );

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
      final result = fetchFileString(cUri, node.dvoteUri);
      return result;
    } catch (err) {
      print(err);
      continue;
    }
  }
  throw ("Could not connect to the network");
}
