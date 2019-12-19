import 'package:dvote/dvote.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/util/net.dart';
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

  //final DataState processMetadataState = DataState();
  final DataState<ProcessMetadata> processMetadata = DataState();

  //final DataState censusDataState = DataState();
  final DataState<bool> isInCensus = DataState();

  //final DataState participationDataState = DataState();
  final DataState<int> participantsTotal = DataState();
  final DataState<int> participantsCurrent = DataState();

  //final DataState datesDataState = DataState();
  final DataState<DateTime> startDate = DataState();
  final DataState<DateTime> endDate = DataState();

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
    await updateCensusStateIfNeeded();
    await updateParticipation();
    await updateDates();

    // Sync process times
    // Check if active?
    // Check participation
    // Check census
    // Check if voted
    // Fetch results
    // Fetch private key
  }

  save() async {
    await processesBloc.add(this.processMetadata.value);
  }

  syncProcessMetadata() {
    ProcessMetadata value = processesBloc.value.firstWhere((process) {
      bool isProcessId = process.meta[META_PROCESS_ID] == this.processId;
      bool isFromEntity =
          process.meta[META_ENTITY_ID] == this.entityReference.entityId;
      bool isFromUser = true;
      return isProcessId && isFromEntity && isFromUser;
    }, orElse: () => null);

    if (value == null)
      this.processMetadata.toUnknown();
    else
      this.processMetadata.value = value;

    if (hasState) rebuildStates([ProcessTags.PROCESS_METADATA]);
  }

  updateProcessMetadataIfNeeded() async {
    if (this.processMetadata.isNotValid) {
      await updateProcessMetadata();
    }
  }

  updateProcessMetadata() async {
    try {
      this.processMetadata.toBootingOrRefreshing();

      final DVoteGateway dvoteGw = getDVoteGateway();
      final Web3Gateway web3Gw = getWeb3Gateway();

      this.processMetadata.value =
          await getProcessMetadata(processId, dvoteGw, web3Gw);

      processMetadata.value.meta[META_PROCESS_ID] = processId;
      processMetadata.value.meta[META_ENTITY_ID] = entityReference.entityId;
    } catch (err) {
      this.processMetadata.toError("Unable to fetch the vote details");
    }
    if (hasState) rebuildStates([ProcessTags.PROCESS_METADATA]);
  }

  syncCensusState() {
    if (this.processMetadata.isNotValid) return;
    try {
      String str = this.processMetadata.value.meta[META_PROCESS_CENSUS_IS_IN];
      if (str == 'true')
        this.isInCensus.value = true;
      else if (str == 'false')
        this.isInCensus.value = false;
      else
        this.isInCensus.toUnknown();
    } catch (e) {
      this.isInCensus.toError(e);
    }
  }

  updateCensusStateIfNeeded() async {
    if (this.isInCensus.isNotValid) await updateCensusState();
  }

  updateCensusState() async {
    if (processMetadata.isNotValid) return;

    final DVoteGateway dvoteGw = getDVoteGateway();

    this.isInCensus.toBooting();
    if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);

    String base64Claim =
        await digestHexClaim(account.identity.keys[0].publicKey);

    try {
      final proof = await generateProof(
          processMetadata.value.census.merkleRoot, base64Claim, dvoteGw);
      if (!(proof is String) || !proof.startsWith("0x")) {
        this.isInCensus.toError("You are not part of the census");

        if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
        return;
      }
      RegExp emptyProofRegexp =
          RegExp(r"^0x[0]+$", caseSensitive: false, multiLine: false);

      if (emptyProofRegexp.hasMatch(proof)) // 0x0000000000.....
        this.isInCensus.value = false;
      else
        this.isInCensus.value = true;

      stageCensusState();
      save();
      if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);

      // final valid = await checkProof(
      //     processMetadata.census.merkleRoot, base64Claim, proof, dvoteGw);
      // if (!valid) {
      //   censusState = CensusState.OUT;
      //   return;
      // }
    } catch (error) {
      this.isInCensus.toError("Unable to check the census");
      if (hasState) rebuildStates([ProcessTags.CENSUS_STATE]);
    }
  }

  stageCensusState() {
    if (processMetadata == null) return null;

    this.processMetadata.value.meta[META_PROCESS_CENSUS_IS_IN] =
        isInCensus.toString();
  }

  Future<int> getTotalParticipants() async {
    if (this.processMetadata == null) return null;

    final DVoteGateway dvoteGw = getDVoteGateway();

    try {
      final size =
          await getCensusSize(processMetadata.value.census.merkleRoot, dvoteGw);
      return size;
    } catch (e) {
      return null;
    }
  }

  Future<int> getCurrentParticipants() async {
    if (processMetadata == null) return null;

    final DVoteGateway dvoteGw = getDVoteGateway();

    try {
      final height = await getEnvelopeHeight(this.processId, dvoteGw);
      return height;
    } catch (e) {
      return null;
    }
  }

  syncParticipation() {
    if (processMetadata.isNotValid) return;
    int total;
    int current;
    try {
      total = int.parse(
          processMetadata.value.meta[META_PROCESS_PARTICIPANTS_TOTAL]);

      current = int.parse(
          processMetadata.value.meta[META_PROCESS_PARTICIPANTS_CURRENT]);
    } catch (e) {}

    if (total == null)
      this.participantsTotal.toUnknown();
    else
      this.participantsTotal.value = total;

    if (total == null)
      this.participantsCurrent.toUnknown();
    else
      this.participantsCurrent.value = current;

    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);
  }

  updateParticipation() async {
    this.participantsTotal.toBootingOrRefreshing();
    this.participantsCurrent.toBootingOrRefreshing();
    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);

    int total = await getTotalParticipants();
    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);

    int current = await getCurrentParticipants();

    if (total == null || total <= 0)
      this.participantsTotal.toError("Invalid census size");
    else
      this.participantsTotal.value = total;

    if (current == null)
      this.participantsCurrent.toError("Invalid amount of participants");
    else
      this.participantsCurrent.value = total;

    stageParticipation();
    save();
    if (hasState) rebuildStates([ProcessTags.PARTICIPATION]);
  }

  stageParticipation() {
    if (participantsTotal.isValid) {
      String total = this.participantsTotal.toString();
      processMetadata.value.meta[META_PROCESS_PARTICIPANTS_TOTAL] = total;
    }

    if (participantsCurrent.isValid) {
      String current = this.participantsCurrent.toString();
      processMetadata.value.meta[META_PROCESS_PARTICIPANTS_CURRENT] = current;
    }
  }

  double get participation {
    if (this.participantsTotal.isNotValid ||
        this.participantsCurrent.isNotValid) return null;

    return this.participantsCurrent.value * 100 / this.participantsTotal.value;
  }

  updateDates() {
    if (!(processMetadata.value is ProcessMetadata)) return;

    //TODO subscribe to vochainModel changes
    if (vochainModel.referenceBlock.isValid) {
      this.startDate.value = DateTime.now().add(
          vochainModel.getDurationUntilBlock(processMetadata.value.startBlock));
      this.endDate.value = DateTime.now().add(
          vochainModel.getDurationUntilBlock(processMetadata.value.startBlock +
              processMetadata.value.numberOfBlocks));
    } else {
      this.startDate.toError("Vochain is not in sync");
      this.endDate.toError("Vochain is not in sync");
    }
  }
}
