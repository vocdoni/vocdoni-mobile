import 'package:http/http.dart' as http;
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/urls.dart' show bootnodesUrl;
// import 'package:vocdoni/constants/vocdoni.dart';

Future<String> getBootNodes() {
  return http.read(bootnodesUrl);
}

Future<String> generateMnemonic() async {
  String mnemonic = await webRuntime.call("generateMnemonic()");
  return mnemonic;
}

Future<String> mnemonicToAddress(String mnemonic) async {
  String address = await webRuntime.call("mnemonicToAddress('$mnemonic')");
  return address;
}

Future<String> mnemonicToPublicKey(String mnemonic) async {
  String address = await webRuntime.call("mnemonicToPublicKey('$mnemonic')");
  return address;
}

Future<Organization> fetchOrganizationInfo(String resolverAddress,
    String entityId, String networkId, List<String> entryPoints) async {
  // Attempt for every node available
  for (BootNode node in appStateBloc.current.bootnodes) {
    try {
      final ethereumUri = node.ethereumUri;
      final dvoteUri = node.dvoteUri;
      final Map<String, dynamic> result = await webRuntime.call('''
        fetchEntityMetadata("$resolverAddress", "$entityId", "$dvoteUri", "$ethereumUri")
      ''');

      final org = Organization.fromJson(result);

      org.resolverAddress = resolverAddress;
      org.entityId = entityId;
      org.networkId = networkId;
      org.entryPoints = entryPoints;

      return org;
    } catch (err) {
      print(err);
      continue;
    }
  }
  return null;
}

Future<String> fetchOrganizationNewsFeed(Organization org, String lang) async {
  // Create a random cloned list
  final List<BootNode> bootnodes = List<BootNode>();
  bootnodes.addAll(appStateBloc.current.bootnodes);
  bootnodes.shuffle();

  if (!(org is Organization))
    return null;
  else if (!(org.newsFeed is Map<String, String>))
    return null;
  else if (!(org.newsFeed[lang] is String)) return null;

  final String contentUri = org.newsFeed[lang];

  // Attempt for every node available
  for (BootNode node in bootnodes) {
    try {
      final result = await webRuntime.call('''
        fetchTextFile("$contentUri", "${node.dvoteUri}")
      ''');
      return result;
    } catch (err) {
      print(err);
      continue;
    }
  }
  throw ("Could not connect to the network");
}
