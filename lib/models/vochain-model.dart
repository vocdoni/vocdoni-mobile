import 'package:dvote/api/voting-process.dart';
import 'package:dvote/net/gateway.dart';
import 'package:vocdoni/data/data-state.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

class VochainModel {
  VochainModel();

  DataState syncDataState = DataState();
  int referenceBlock;
  DateTime referenceTimestamp;

  syncBlockHeight(){
    //TODO
  }

  updateBlockHeight() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    syncDataState.toBootingOrRefreshing();

    try {
      this.referenceBlock = await getBlockHeight(dvoteGw);
      syncDataState.toGood();
    } catch (e) {
      this.referenceBlock = 0;
      syncDataState.toErrorOrFaulty(e);
    }
    this.referenceTimestamp = DateTime.now();
    //TODO save to storage
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
