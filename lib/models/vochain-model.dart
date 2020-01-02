import 'package:dvote/api/voting-process.dart';
import 'package:dvote/net/gateway.dart';
import 'package:vocdoni/lib/value-state.dart';
import 'package:vocdoni/util/net.dart';
import 'package:vocdoni/util/singletons.dart';

class VochainModel {
  VochainModel();

  final ValueState<int> referenceBlock = new ValueState();
  final ValueState<DateTime> referenceTimestamp = new ValueState();

  syncBlockHeight() {
    //TODO
  }

  updateBlockHeight() async {
    this.referenceBlock.setToLoading();
    final DVoteGateway dvoteGw = getDVoteGateway();

    try {
      final newReferenceblock = await getBlockHeight(dvoteGw);

      if (newReferenceblock == null) {
        this.referenceBlock.setError("Unable to retrieve reference block");
        this.referenceTimestamp.setError("Unable to retrieve reference block");
      } else {
        this.referenceBlock.setValue(newReferenceblock);
        this.referenceTimestamp.setValue(DateTime.now());
      }
    } catch (err) {
      this.referenceBlock.setError("Network error");
      print(err);
      throw err;
    }
    //TODO save to storage
  }

  Duration getDurationUntilBlock(int blockNumber) {
    if (!this.referenceBlock.hasValue) return null;
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
