import 'package:dvote/dvote.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

enum ProcessTags {
  PROCESS_METADATA,
  CENSUS_STATE,
  PARTICIPATION,
  VOTE_CONFIRMED
}

class ProcessModel extends StatesRebuilder {
  String processId;
  EntityReference entityReference;
  String lang = "default";

  final DataState processMetadataState = DataState();
  ProcessMetadata processMetadata;

  final DataState censusDataState = DataState();
  bool censusIsIn;

  final DataState participationDataState = DataState();
  int participantsTotal;
  int participantsCurrent;

  final DataState datesDataState = DataState();
  DateTime startDate;
  DateTime endDate;

  ProcessModel({this.processId, this.entityReference}) {
    syncLocal();
  }

  syncLocal() {
    syncProcessMetadata();
    syncCensusState();
    syncParticipation();
  }

  update() async {
    syncLocal();
    await updateProcessMetadataIfNeeded();
    updateCensusStateIfNeeded();
    updateParticipation();
    updateDates();
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
    await processesBloc.add(this.processMetadata);
  }

  syncProcessMetadata() {
    this.processMetadata = processesBloc.value.firstWhere((process) {
      return process.meta[META_PROCESS_ID] == this.processId;
    }, orElse: () => null);

    if (this.processMetadata == null)
      this.processMetadataState.toUnknown();
    else
      this.processMetadataState.toGood();

    if (hasState) rebuildStates([ProcessTags.PROCESS_METADATA]);
  }

  updateProcessMetadataIfNeeded() async {
    if (this.processMetadataState.isNotValid) {
      await updateProcessMetadata();
    }
  }

  updateProcessMetadata() async {
    try {
      this.processMetadataState.toBootingOrRefreshing();
      final gwInfo = selectRandomGatewayInfo();

      final DVoteGateway dvoteGw =
          DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);
      final Web3Gateway web3Gw = Web3Gateway(gwInfo.web3);

      this.processMetadata =
          await getProcessMetadata(processId, dvoteGw, web3Gw);

      processMetadata.meta[META_PROCESS_ID] = processId;
      processMetadata.meta[META_ENTITY_ID] = entityReference.entityId;

      this.processMetadataState.toGood();
    } catch (err) {
      this.processMetadataState.toError("Unable to update processMetadata");
    }
    if (hasState) rebuildStates([ProcessTags.PROCESS_METADATA]);
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
      this.censusDataState.toUnknown();
    else
      this.censusDataState.toGood();
    if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
  }

  updateCensusStateIfNeeded() async {
    if (this.censusDataState.isNotValid) await updateCensusState();
  }

  updateCensusState() async {
    this.censusDataState.toRefreshing();
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
        this.censusDataState.toError("Census-proof is not valid");
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

      this.censusDataState.toGood();
      stageCensusState();
      if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);

      // final valid = await checkProof(
      //     processMetadata.census.merkleRoot, base64Claim, proof, dvoteGw);
      // if (!valid) {
      //   censusState = CensusState.OUT;
      //   return;
      // }
    } catch (error) {
      this.censusDataState.toError("Unable to validate census-proof");
      if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
    }
  }

  stageCensusState() {
    if (processMetadata == null) return null;

    this.processMetadata.meta[META_PROCESS_CENSUS_IS_IN] =
        censusIsIn.toString();
  }

  Future<int> getTotalParticipants() async {
    if (this.processMetadata == null) return null;

    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    try {
      return await getCensusSize(processMetadata.census.merkleRoot, dvoteGw);
    } catch (e) {
      return null;
    }
  }

  Future<int> getCurrentParticipants() async {
    if (processMetadata == null) return null;
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    try {
      return await getEnvelopeHeight(
          processMetadata.meta[META_PROCESS_ID], dvoteGw);
    } catch (e) {
      return null;
    }
  }

  syncParticipation() {
    if (processMetadata == null) return;
    try {
      this.participantsTotal =
          int.parse(processMetadata.meta[META_PROCESS_PARTICIPANTS_TOTAL]);
      this.participantsCurrent =
          int.parse(processMetadata.meta[META_PROCESS_PARTICIPANTS_CURRENT]);
    } catch (e) {
      this.participantsTotal = null;
      this.participantsCurrent = null;
    }

    if (this.participantsTotal == null || this.participantsCurrent == null)
      this.participationDataState.toUnknown();
    else
      this.censusDataState.toGood();
    stageParticipation();
    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);
  }

  updateParticipation() async {
    this.participationDataState.toBootingOrRefreshing();
    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);
    this.participantsTotal = await getTotalParticipants();
    this.participantsCurrent = await getCurrentParticipants();
    if (this.participantsTotal == null || this.participantsCurrent == null)
      this.participationDataState.toError('Participation data is invalid');
    else
      this.participationDataState.toGood();
    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);
  }

  stageParticipation() {
    if (participationDataState.isValid) return;
    processMetadata.meta[META_PROCESS_PARTICIPANTS_TOTAL] =
        this.participantsTotal.toString();
    processMetadata.meta[META_PROCESS_PARTICIPANTS_CURRENT] =
        this.participantsCurrent.toString();
  }

  double get participation {
    if (this.participantsTotal <= 0) return 0.0;
    return this.participantsCurrent * 100 / this.participantsTotal;
  }

  updateDates() {
    //TODO subscribe to vochainModel changes
    if (vochainModel.syncDataState.isValid) {
      this.startDate = DateTime.now()
          .add(vochainModel.getDurationUntilBlock(processMetadata.startBlock));
      this.endDate = DateTime.now().add(vochainModel.getDurationUntilBlock(
          processMetadata.startBlock + processMetadata.numberOfBlocks));
      this.datesDataState.toGood();
    } else {
      this.datesDataState.toError("Vochain is not in sync");
    }
  }
}
