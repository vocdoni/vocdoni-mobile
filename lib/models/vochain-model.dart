import 'package:dvote/api/voting-process.dart';
import 'package:dvote/net/gateway.dart';
import 'package:vocdoni/data/data-state.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

class VochainModel {
  VochainModel();

  final DataState<int> referenceBlock = new DataState();
  final DataState<DateTime> referenceTimestamp = new DataState();

  syncBlockHeight() {
    //TODO
  }

  updateBlockHeight() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    this.referenceBlock.toBootingOrRefreshing();
    final newReferenceblock = await getBlockHeight(dvoteGw);
    if (newReferenceblock == null) {
      this.referenceBlock.toErrorOrFaulty("Unable to retrieve reference block");
      this
          .referenceTimestamp
          .toErrorOrFaulty("Unable to retrieve reference block");
    } else {
      this.referenceBlock.value = newReferenceblock;
      this.referenceTimestamp.value = DateTime.now();
    }
    //TODO save to storage
  }

  Duration getDurationUntilBlock(int blockNumber) {
    if (this.referenceBlock.isNotValid) return null;
    int blocksLeftFromReference = blockNumber - referenceBlock.value;
    Duration referenceToBlock = blocksToDuration(blocksLeftFromReference);
    Duration nowToReference =
        DateTime.now().difference(referenceTimestamp.value);
    return nowToReference - referenceToBlock;
  }

  Duration blocksToDuration(int blocks) {
    //TODO fetch average block time
    int averageBlockTime = 5; //seconds
    return new Duration(seconds: averageBlockTime * blocks);
  }
}
