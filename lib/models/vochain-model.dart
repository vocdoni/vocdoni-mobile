import 'package:dvote/api/voting-process.dart';
import 'package:dvote/net/gateway.dart';
import 'package:vocdoni/data/data-state.dart';
import 'package:vocdoni/util/api.dart';

class VochainModel {
  VochainModel();

  DataState blockReferenceDataState = DataState();
  int blockReference;
  DateTime timeReference;

  updateBlockHeight() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    blockReferenceDataState.toBootingOrRefreshing();

    try {
      this.blockReference = await getBlockHeight(dvoteGw);
      blockReferenceDataState.toGood();
    } catch (e) {
      this.blockReference = 0;
      blockReferenceDataState.toErrorOrFaulty();
    }
    this.timeReference = DateTime.now();
  }
}
