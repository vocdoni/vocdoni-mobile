import 'package:dvote/dvote.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

// Watchout changing this
enum CensusState { IN, OUT, UNKNOWN, ERROR }

class Process {
  String processId;
  EntityReference entityReference;
  ProcessMetadata processMetadata;
  String lang = "default";
  CensusState censusState = CensusState.UNKNOWN;

  Process({this.processId, this.entityReference}) {
    syncLocal();
  }

  syncLocal() {
    syncProcessMetadata();
    syncCensusState();
  }

  update() async {
    syncProcessMetadata();
    await fetchProcessMetadataIfNeeded();
    syncCensusState();
    await fetchCensusStateIfNeeded();
    save();

    // Sync process times
    // Check if active?
    // Check census
    // Check if voted
    // Fetch results
    // Fetch private key
  }

  save() async {
    censusStateToMeta();
    await processesBloc.add(this.processMetadata);
  }

  syncProcessMetadata() {
    this.processMetadata = processesBloc.value.firstWhere((process) {
      return process.meta[META_PROCESS_ID] == this.processId;
    }, orElse: () => null);
  }

  fetchProcessMetadataIfNeeded() async {
    if (this.processMetadata == null) {
      this.processMetadata = await fetchProcess(entityReference, processId);
    }
  }

  syncCensusState() {
    try {
      censusState = CensusState.values.firstWhere(
          (e) =>
              e.toString() ==
              'CensusState.' +
                  this.processMetadata.meta[META_PROCESS_CENSUS_STATE],
          orElse: () => censusState = CensusState.UNKNOWN);
    } catch (e) {
      censusState = CensusState.UNKNOWN;
    }
  }

  fetchCensusStateIfNeeded() async {
    if (this.censusState != CensusState.IN &&
        this.censusState != CensusState.OUT) await checkCensusState();
  }

  checkCensusState() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    String base64Claim =
        await digestHexClaim(account.identity.keys[0].publicKey);
    try {
      final proof = await generateProof(
          processMetadata.census.merkleRoot, base64Claim, dvoteGw);
      if (!(proof is String) || !proof.startsWith("0x")) {
        censusState = CensusState.OUT;
        return;
      }

      // final valid = await checkProof(
      //     processMetadata.census.merkleRoot, base64Claim, proof, dvoteGw);
      // if (!valid) {
      //   censusState = CensusState.OUT;
      //   return;
      // }
      censusState = CensusState.IN;
    } catch (error) {
      censusState = CensusState.ERROR;
    }
  }

  censusStateToMeta() async {
    if (this.censusState == CensusState.IN ||
        this.censusState == CensusState.OUT) {
      this.processMetadata.meta[META_PROCESS_CENSUS_STATE] =
          censusState.toString();
    }
  }

  Future<int> getTotalParticipants() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    int total = -1;

    try {
      total = await getCensusSize(processMetadata.census.merkleRoot, dvoteGw);
    } catch (e) {}
    return total;
  }

  Future<int> getCurrentParticipants() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    int current = -1;
    try {
      current = await getEnvelopeHeight(
          processMetadata.meta[META_PROCESS_ID], dvoteGw);
    } catch (e) {}
    return current;
  }

  Future<double> getParticipation() async {
    int total = await getTotalParticipants();
    int current = await getCurrentParticipants();
    if (total == -1 || current == -1) return -1;
    int p = (current / total * 1000).round();
    return p / 10;
  }

  DateTime getStartDate() {
    return DateTime.now().add(getDurationUntilBlock(
        vochainTimeRef, vochainBlockRef, processMetadata.startBlock));
  }

  DateTime getEndDate() {
    return DateTime.now().add(getDurationUntilBlock(
        vochainTimeRef,
        vochainBlockRef,
        processMetadata.startBlock + processMetadata.numberOfBlocks));
  }

  //TODO use dvote api instead once they removed getEnvelopHeight
  Duration getDurationUntilBlock(
      DateTime referenceTimeStamp, int referenceBlock, int blockNumber) {
    int blocksLeftFromReference = blockNumber - referenceBlock;
    Duration referenceToBlock = blocksToDuration(blocksLeftFromReference);
    Duration nowToReference = DateTime.now().difference(referenceTimeStamp);
    return nowToReference - referenceToBlock;
  }

  Duration blocksToDuration(int blocks) {
    int averageBlockTime = 5; //seconds
    return new Duration(seconds: averageBlockTime * blocks);
  }
}
