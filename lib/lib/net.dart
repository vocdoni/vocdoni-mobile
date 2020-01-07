import 'dart:convert';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/constants/settings.dart';

DVoteGateway _dvoteGw;
Web3Gateway _web3Gw;

connectGateways() {
  if (_dvoteGw is DVoteGateway) _dvoteGw.disconnect();
  if (_web3Gw is Web3Gateway) _web3Gw.disconnect();

  final gwInfo = _selectRandomGatewayInfo();
  if (gwInfo == null) throw "There is no gateway available";

  _dvoteGw = DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);
  _web3Gw = Web3Gateway(gwInfo.web3);
}

bool hasGatewaysConnected() =>
    _dvoteGw is DVoteGateway && _web3Gw is Web3Gateway;

DVoteGateway getDVoteGateway() {
  if (!hasGatewaysConnected()) connectGateways();
  return _dvoteGw;
}

Web3Gateway getWeb3Gateway() {
  if (!hasGatewaysConnected()) connectGateways();
  return _web3Gw;
}

GatewayInfo _selectRandomGatewayInfo() {
  if (!globalAppState.hasValue || !globalAppState.value.bootnodes.hasValue)
    return null;

  final gw = GatewayInfo();

  if (NETWORK_ID == "homestead") {
    if (globalAppState.value.bootnodes.value.homestead.dvote.length < 1) {
      print("The DVote gateway list is empty for Homestead");
      return null;
    }

    // PROD
    int dvoteIdx = random
        .nextInt(globalAppState.value.bootnodes.value.homestead.dvote.length);
    int web3Idx = random
        .nextInt(globalAppState.value.bootnodes.value.homestead.web3.length);

    gw.dvote =
        globalAppState.value.bootnodes.value.homestead.dvote[dvoteIdx].uri;
    gw.publicKey =
        globalAppState.value.bootnodes.value.homestead.dvote[dvoteIdx].pubKey;
    gw.supportedApis.addAll(
        globalAppState.value.bootnodes.value.homestead.dvote[dvoteIdx].apis);
    gw.web3 = globalAppState.value.bootnodes.value.homestead.web3[web3Idx].uri;
  } else {
    if (globalAppState.value.bootnodes.value.goerli.dvote.length < 1) {
      print("The DVote gateway list is empty for Goerli");
      return null;
    }

    // DEV
    int dvoteIdx = random
        .nextInt(globalAppState.value.bootnodes.value.goerli.dvote.length);
    int web3Idx =
        random.nextInt(globalAppState.value.bootnodes.value.goerli.web3.length);

    gw.dvote = globalAppState.value.bootnodes.value.goerli.dvote[dvoteIdx].uri;
    gw.publicKey =
        globalAppState.value.bootnodes.value.goerli.dvote[dvoteIdx].pubKey;
    gw.supportedApis.addAll(
        globalAppState.value.bootnodes.value.goerli.dvote[dvoteIdx].apis);
    gw.web3 = globalAppState.value.bootnodes.value.goerli.web3[web3Idx].uri;
  }
  return gw;
}

/*
 * Get a URI providing the given string content
 */
String uriFromContent(String content) {
  return new Uri.dataFromString(content,
          mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
      .toString();
}
