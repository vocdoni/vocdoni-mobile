import '../util/singletons.dart';

Future<String> generateMnemonic() async {
  String mnemonic = await webRuntime.call("generateMnemonic()");
  return mnemonic;
}

Future<String> mnemonicToAddress(String mnemonic) async {
  String address = await webRuntime.call("mnemonicToAddress('$mnemonic')");
  return address;
}

Future<Organization> fetchOrganizationInfo(String resolverAddress,
    String entityId, String networkId, List<String> entryPoints) async {
  print("FETCH organization $resolverAddress, $entityId");

  // TODO: fetch

  return Organization(name: "TEMP", resolverAddress: "0x1234", entityId: "0x2345", networkId: "1234", entryPoints: ["http://gw.io"]);
}
