import '../util/singletons.dart';

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
  // TODO: TEMP: USE A REAL $providerUrl
  final providerUrl = "http://node.testnet.vocdoni.io:8545";

  final Map<String, dynamic> result = await webRuntime.call('''
    fetchEntity("$resolverAddress", "$entityId", "$providerUrl")
  ''');

  final org = Organization.fromJson(result);

  org.resolverAddress = resolverAddress;
  org.entityId = entityId;
  org.networkId = networkId;
  org.entryPoints = entryPoints;

  return org;
}
