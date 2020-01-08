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
  if (appStateBloc.value == null || appStateBloc.value.bootnodes == null)
    return null;

  final gw = GatewayInfo();

  if (NETWORK_ID == "homestead") {
    if (appStateBloc.value.bootnodes.homestead.dvote.length < 1) {
      print("The DVote gateway list is empty for Homestead");
      return null;
    }

    // PROD
    int dvoteIdx =
        random.nextInt(appStateBloc.value.bootnodes.homestead.dvote.length);
    int web3Idx =
        random.nextInt(appStateBloc.value.bootnodes.homestead.web3.length);

    gw.dvote = appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].uri;
    gw.publicKey =
        appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].apis);
    gw.web3 = appStateBloc.value.bootnodes.homestead.web3[web3Idx].uri;
  } else {
    if (appStateBloc.value.bootnodes.goerli.dvote.length < 1) {
      print("The DVote gateway list is empty for Goerli");
      return null;
    }

    // DEV
    int dvoteIdx =
        random.nextInt(appStateBloc.value.bootnodes.goerli.dvote.length);
    int web3Idx =
        random.nextInt(appStateBloc.value.bootnodes.goerli.web3.length);

    gw.dvote = appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].uri;
    gw.publicKey = appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].apis);
    gw.web3 = appStateBloc.value.bootnodes.goerli.web3[web3Idx].uri;
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
