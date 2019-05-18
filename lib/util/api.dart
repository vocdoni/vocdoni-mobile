import 'package:http/http.dart' as http;
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/urls.dart' show bootnodesUrl;

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
  for (BootNode node in appStateBloc.current.bootnodes) {
    final providerUri = node.ethereumUri;
    // Attempt for every node
    try {
      final Map<String, dynamic> result = await webRuntime.call('''
        fetchEntity("$resolverAddress", "$entityId", "$providerUri")
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
