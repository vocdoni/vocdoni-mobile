import 'package:http/http.dart' as http;
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/urls.dart' show bootnodesUrl;
import 'package:vocdoni/util/random.dart';
import 'package:dvote/dvote.dart';
// import 'package:vocdoni/constants/vocdoni.dart';

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

Future<Organization> fetchOrganizationInfo(String resolverAddress,
    String entityId, String networkId, List<String> entryPoints) async {
  // TODO: Make a real web socket connection
  return null;

  // Uri parsedUri, ethereumUri;
  // final String randomSuffix = randomString();

  // // Attempt for every node available
  // for (BootNode node in appStateBloc.current.bootnodes) {
  //   try {
  //     // randomize the path to prevent caching
  //     parsedUri = Uri.parse(node.ethereumUri);
  //     ethereumUri = Uri(
  //         scheme: parsedUri.scheme,
  //         host: parsedUri.host,
  //         port: parsedUri.port,
  //         path: "${parsedUri?.path ?? '/web3'}/$randomSuffix",
  //         query: parsedUri.query);
  //     final dvoteUri = node.dvoteUri;
  //     final Map<String, dynamic> result = await webRuntime.call('''
  //       fetchEntityMetadata("$resolverAddress", "$entityId", "$dvoteUri", "${ethereumUri.toString()}")
  //     ''');

  //     final org = Organization.fromJson(result);

  //     org.resolverAddress = resolverAddress;
  //     org.entityId = entityId;
  //     org.networkId = networkId;
  //     org.entryPoints = entryPoints;

  //     return org;
  //   } catch (err) {
  //     print(err);
  //     continue;
  //   }
  // }
  // return null;
}

Future<String> fetchOrganizationNewsFeed(Organization org, String lang) async {
  // TODO: Make a real web socket connection
  return null;

  // // Create a random cloned list
  // final List<BootNode> bootnodes = List<BootNode>();
  // bootnodes.addAll(appStateBloc.current.bootnodes);
  // bootnodes.shuffle();

  // if (!(org is Organization))
  //   return null;
  // else if (!(org.newsFeed is Map<String, String>))
  //   return null;
  // else if (!(org.newsFeed[lang] is String)) return null;

  // final String contentUri = org.newsFeed[lang];

  // // Attempt for every node available
  // for (BootNode node in bootnodes) {
  //   try {
  //     final result = await webRuntime.call('''
  //       fetchTextFile("$contentUri", "${node.dvoteUri}")
  //     ''');
  //     return result;
  //   } catch (err) {
  //     print(err);
  //     continue;
  //   }
  // }
  // throw ("Could not connect to the network");
}
