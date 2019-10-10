import 'package:dvote/api/voting-process.dart';
import 'package:dvote/net/gateway.dart';
import 'package:vocdoni/data/data-state.dart';
import 'package:vocdoni/util/api.dart';

class VochainModel {
  VochainModel();

  DataState blockReferenceDataState = DataState();
  int referenceBlock;
  DateTime referenceTimestamp;

  updateBlockHeight() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    blockReferenceDataState.toBootingOrRefreshing();

    try {
      this.referenceBlock = await getBlockHeight(dvoteGw);
      blockReferenceDataState.toGood();
    } catch (e) {
      this.referenceBlock = 0;
      blockReferenceDataState.toErrorOrFaulty();
    }
    this.referenceTimestamp = DateTime.now();
  }

  Duration getDurationUntilBlock(int blockNumber) {
    int blocksLeftFromReference = blockNumber - referenceBlock;
    Duration referenceToBlock = blocksToDuration(blocksLeftFromReference);
    Duration nowToReference = DateTime.now().difference(referenceTimestamp);
    return nowToReference - referenceToBlock;
  }

  Duration blocksToDuration(int blocks) {
    int averageBlockTime = 5; //seconds
    return new Duration(seconds: averageBlockTime * blocks);
  }
}
