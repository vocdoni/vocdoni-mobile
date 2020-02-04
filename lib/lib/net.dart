import 'dart:convert';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/lib/util.dart';

DVoteGateway _dvoteGw;
Web3Gateway _web3Gw;
bool connecting = false;

ensureConnectedGateways() {
  if (connecting) return;

  final gwInfo = _selectRandomGatewayInfo();
  if (gwInfo == null) throw Exception("There is no gateway available");

  connecting = true;
  if (_dvoteGw is DVoteGateway) {
    if (!_dvoteGw.isConnected) {
      // TODO: ON .connect() EXCEPTION RETRY UNTIL OK
      if (_dvoteGw.publicKey == gwInfo.publicKey)
        _dvoteGw.connect(gwInfo.dvote);
      else {
        _dvoteGw = DVoteGateway(gwInfo.dvote,
            publicKey: gwInfo.publicKey,
            onTimeout: _onGatewayTimeout); // calls `connect()` internally
      }
    }
  } else {
    _dvoteGw = DVoteGateway(gwInfo.dvote,
        publicKey: gwInfo.publicKey,
        onTimeout: _onGatewayTimeout); // calls `connect()` internally
  }

  if (!(_web3Gw is Web3Gateway)) {
    _web3Gw = Web3Gateway(gwInfo.web3);
  }
  connecting = false;
}

void _onGatewayTimeout() {
  devPrint("GW timeout handler: RECONNECTING TO ${_dvoteGw.uri}");
  _dvoteGw.reconnect(null);
}

bool areGatewaysConnected() =>
    _dvoteGw is DVoteGateway && _dvoteGw.isConnected && _web3Gw is Web3Gateway;

DVoteGateway getDVoteGateway() {
  if (!areGatewaysConnected()) ensureConnectedGateways();
  return _dvoteGw;
}

Web3Gateway getWeb3Gateway() {
  if (!areGatewaysConnected()) ensureConnectedGateways();
  return _web3Gw;
}

GatewayInfo _selectRandomGatewayInfo() {
  if (!globalAppState.bootnodes.hasValue) return null;

  final gw = GatewayInfo();

  if (NETWORK_ID == "homestead") {
    if (globalAppState.bootnodes.value.homestead.dvote.length < 1) {
      print("The DVote gateway list is empty for Homestead");
      return null;
    }

    // PROD
    int dvoteIdx =
        random.nextInt(globalAppState.bootnodes.value.homestead.dvote.length);
    int web3Idx =
        random.nextInt(globalAppState.bootnodes.value.homestead.web3.length);

    gw.dvote = globalAppState.bootnodes.value.homestead.dvote[dvoteIdx].uri;
    gw.publicKey =
        globalAppState.bootnodes.value.homestead.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(globalAppState.bootnodes.value.homestead.dvote[dvoteIdx].apis);
    gw.web3 = globalAppState.bootnodes.value.homestead.web3[web3Idx].uri;
  } else {
    if (globalAppState.bootnodes.value.goerli.dvote.length < 1) {
      print("The DVote gateway list is empty for Goerli");
      return null;
    }

    // DEV
    int dvoteIdx =
        random.nextInt(globalAppState.bootnodes.value.goerli.dvote.length);
    int web3Idx =
        random.nextInt(globalAppState.bootnodes.value.goerli.web3.length);

    gw.dvote = globalAppState.bootnodes.value.goerli.dvote[dvoteIdx].uri;
    gw.publicKey = globalAppState.bootnodes.value.goerli.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(globalAppState.bootnodes.value.goerli.dvote[dvoteIdx].apis);
    gw.web3 = globalAppState.bootnodes.value.goerli.web3[web3Idx].uri;
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
