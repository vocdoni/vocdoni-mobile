import 'package:dvote/dvote.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

enum DataState { UNKNOWN, CHECKING, GOOD, ERROR }
enum ProcessTags { CENSUS_STATE, PARTICIPATION, VOTE_CONFIRMED }

class ProcessModel extends StatesRebuilder {
  String processId;
  EntityReference entityReference;
  ProcessMetadata processMetadata;
  String lang = "default";

  DataState censusDataState = DataState.UNKNOWN;
  bool censusIsIn;

  DataState participationDataState = DataState.UNKNOWN;
  int participantsTotal;
  int participantsCurrent;

  ProcessModel({this.processId, this.entityReference}) {
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
    await updateCensus();
    save();

    // Sync process times
    // Check if active?
    // Check participation
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
      String str = this.processMetadata.meta[META_PROCESS_CENSUS_IS_IN];
      if (str == 'true')
        this.censusIsIn = true;
      else if (str == 'false')
        this.censusIsIn = false;
      else
        this.censusIsIn = null;
    } catch (e) {
      this.censusIsIn = null;
    }
    if (this.censusIsIn == null)
      this.censusDataState = DataState.UNKNOWN;
    else
      this.censusDataState = DataState.GOOD;
    if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
  }

  updateCensus() async {
    if (this.censusDataState != DataState.GOOD) await checkCensusState();
  }

  checkCensusState() async {
    this.censusDataState = DataState.CHECKING;
    if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
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
        this.censusDataState = DataState.ERROR;
        this.censusIsIn = false;

        if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
        return;
      }
      RegExp emptyProofRegexp =
          RegExp(r"^0x[0]+$", caseSensitive: false, multiLine: false);

      if (emptyProofRegexp.hasMatch(proof)) // 0x0000000000.....
        this.censusIsIn = false;
      else
        this.censusIsIn = true;

      this.censusDataState = DataState.GOOD;
      if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);

      // final valid = await checkProof(
      //     processMetadata.census.merkleRoot, base64Claim, proof, dvoteGw);
      // if (!valid) {
      //   censusState = CensusState.OUT;
      //   return;
      // }
    } catch (error) {
      this.censusDataState = DataState.ERROR;
      if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
    }
  }

  censusStateToMeta() async {
    if (processMetadata == null) return null;

    this.processMetadata.meta[META_PROCESS_CENSUS_IS_IN] =
        censusIsIn.toString();
  }

  Future<int> getTotalParticipants() async {
    if (this.processMetadata == null) return 0;

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

  updateParticipation() async {
    this.participantsTotal = await getTotalParticipants();
    this.participantsCurrent = await getCurrentParticipants();
    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);
  }

  double get participation {
    if (this.participantsTotal <= 0) return 0.0;
    return this.participantsCurrent * 100 / this.participantsTotal;
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
