import 'package:dvote/dvote.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

// Watchout changing this
enum CensusState { IN, OUT, CHECKING, UNKNOWN, ERROR }
enum ProcessTags { CENSUS_STATE, VOTE_CONFIRMED }

class Process extends StatesRebuilder {
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
    if (processMetadata == null) return;
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
    rebuildStates([ProcessTags.CENSUS_STATE]);
  }

  fetchCensusStateIfNeeded() async {
    if (this.censusState != CensusState.IN &&
        this.censusState != CensusState.OUT) await checkCensusState();
  }

  checkCensusState() async {
    this.censusState=CensusState.CHECKING;
    rebuildStates([ProcessTags.CENSUS_STATE]);
    if (processMetadata == null) return;
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    String base64Claim =
        await digestHexClaim(account.identity.keys[0].publicKey);
    try {
      final proof = await generateProof(
          processMetadata.census.merkleRoot, base64Claim, dvoteGw);
      if (!(proof is String) || !proof.startsWith("0x")) {
        this.censusState = CensusState.OUT;
        rebuildStates([ProcessTags.CENSUS_STATE]);
        return;
      }
      RegExp emptyProofRegexp =
          RegExp(r"^0x[0]+$", caseSensitive: false, multiLine: false);

      if (emptyProofRegexp.hasMatch(proof)) // 0x0000000000.....
        this.censusState = CensusState.OUT;
      else
        censusState = CensusState.IN;

      rebuildStates([ProcessTags.CENSUS_STATE]);

      // final valid = await checkProof(
      //     processMetadata.census.merkleRoot, base64Claim, proof, dvoteGw);
      // if (!valid) {
      //   censusState = CensusState.OUT;
      //   return;
      // }
    } catch (error) {
      this.censusState = CensusState.ERROR;
      rebuildStates([ProcessTags.CENSUS_STATE]);
    }
  }

  censusStateToMeta() async {
    if (processMetadata == null) return null;
    if (this.censusState == CensusState.IN ||
        this.censusState == CensusState.OUT) {
      this.processMetadata.meta[META_PROCESS_CENSUS_STATE] =
          censusState.toString();
    }
  }

  Future<int> getTotalParticipants() async {
    if (processMetadata == null) return 0;
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
    if (processMetadata == null) return 0;
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

  Future<int> getParticipation() async {
    int total = await getTotalParticipants();
    int current = await getCurrentParticipants();
    if (total <= 0 || current <= 0) return -1;
    return (current * 100 / total).round();
  }

  DateTime getStartDate() {
    if (processMetadata == null) return null;
    return DateTime.now().add(getDurationUntilBlock(
        vochainTimeRef, vochainBlockRef, processMetadata.startBlock));
  }

  DateTime getEndDate() {
    if (processMetadata == null) return null;
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
