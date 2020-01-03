import 'package:dvote/dvote.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/singletons.dart';
import "package:vocdoni/constants/meta-keys.dart";
import 'package:vocdoni/lib/value-state.dart';

enum ProcessStateTags {
  PROCESS_METADATA,
  CENSUS_STATE,
  PARTICIPATION,
  VOTE_CONFIRMED
}

class ProcessModel extends StatesRebuilder {
  String processId;
  EntityReference entityReference;
  String lang = "default";

  final ValueState<ProcessMetadata> processMetadata = ValueState();

  final ValueState<bool> isInCensus = ValueState();
  final ValueState<bool> hasVoted = ValueState();

  final ValueState<int> participantsTotal = ValueState();
  final ValueState<int> participantsCurrent = ValueState();

  final ValueState<DateTime> startDate = ValueState();
  final ValueState<DateTime> endDate = ValueState();

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
      this.processMetadata.setError("Not found");
    else
      this.processMetadata.setValue(value);

    if (hasState) rebuildStates([ProcessStateTags.PROCESS_METADATA]);
  }

  updateProcessMetadataIfNeeded() async {
    if (!this.processMetadata.hasValue) {
      await updateProcessMetadata();
    }
  }

  updateProcessMetadata() async {
    try {
      this.processMetadata.setToLoading();

      final DVoteGateway dvoteGw = getDVoteGateway();
      final Web3Gateway web3Gw = getWeb3Gateway();

      this
          .processMetadata
          .setValue(await getProcessMetadata(processId, dvoteGw, web3Gw));

      processMetadata.value.meta[META_PROCESS_ID] = processId;
      processMetadata.value.meta[META_ENTITY_ID] = entityReference.entityId;
    } catch (err) {
      this.processMetadata.setError("Unable to fetch the vote details");
    }
    if (hasState) rebuildStates([ProcessStateTags.PROCESS_METADATA]);
  }

  syncCensusState() {
    if (!this.processMetadata.hasValue) return;
    try {
      String str = this.processMetadata.value.meta[META_PROCESS_CENSUS_IS_IN];
      if (str == 'true')
        this.isInCensus.setValue(true);
      else if (str == 'false')
        this.isInCensus.setValue(false);
      else
        this.isInCensus.setError("Not found");
    } catch (e) {
      this.isInCensus.setError(e?.toString());
    }
  }

  updateCensusStateIfNeeded() async {
    if (!this.isInCensus.hasValue) await updateCensusState();
  }

  updateCensusState() async {
    if (!processMetadata.hasValue) return;

    final DVoteGateway dvoteGw = getDVoteGateway();

    this.isInCensus.setToLoading();
    if (hasState) rebuildStates([ProcessStateTags.CENSUS_STATE]);

    String base64Claim =
        await digestHexClaim(account.identity.keys[0].publicKey);

    try {
      final proof = await generateProof(
          processMetadata.value.census.merkleRoot, base64Claim, dvoteGw);
      if (!(proof is String) || !proof.startsWith("0x")) {
        this.isInCensus.setError("You are not part of the census");

        if (hasState) rebuildStates([ProcessStateTags.CENSUS_STATE]);
        return;
      }
      RegExp emptyProofRegexp =
          RegExp(r"^0x[0]+$", caseSensitive: false, multiLine: false);

      if (emptyProofRegexp.hasMatch(proof)) // 0x0000000000.....
        this.isInCensus.setValue(false);
      else
        this.isInCensus.setValue(true);

      stageCensusState();
      save();
      if (hasState) rebuildStates([ProcessStateTags.CENSUS_STATE]);

      // final valid = await checkProof(
      //     processMetadata.census.merkleRoot, base64Claim, proof, dvoteGw);
      // if (!valid) {
      //   censusState = CensusState.OUT;
      //   return;
      // }
    } catch (error) {
      this.isInCensus.setError("Unable to check the census");
      if (hasState) rebuildStates([ProcessStateTags.CENSUS_STATE]);
    }
  }

  updateHasVoted() async {
    if (!this.hasVoted.hasError && this.hasVoted.value == true) return;

    final String pollNullifier = getPollNullifier(
        identitiesBloc.getCurrentIdentity().keys[0].address, this.processId);

    final DVoteGateway dvoteGw = getDVoteGateway();
    final success =
        await getEnvelopeStatus(this.processId, pollNullifier, dvoteGw)
            .catchError((_) {});

    if (success is bool) {
      this.hasVoted.setValue(success);
    } else {
      this.hasVoted.setError("Unable to check the process status");
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
    if (!processMetadata.hasValue) return;
    int total;
    int current;
    try {
      total = int.parse(
          processMetadata.value.meta[META_PROCESS_PARTICIPANTS_TOTAL]);

      current = int.parse(
          processMetadata.value.meta[META_PROCESS_PARTICIPANTS_CURRENT]);
    } catch (e) {}

    if (total == null)
      this.participantsTotal.setError("Not found");
    else
      this.participantsTotal.setValue(total);

    if (total == null)
      this.participantsCurrent.setError("Not found");
    else
      this.participantsCurrent.setValue(current);

    if (hasState) rebuildStates([ProcessStateTags.PARTICIPATION]);
  }

  updateParticipation() async {
    this.participantsTotal.setToLoading();
    this.participantsCurrent.setToLoading();
    if (hasState) rebuildStates([ProcessStateTags.PARTICIPATION]);

    int total = await getTotalParticipants();
    if (hasState) rebuildStates([ProcessStateTags.PARTICIPATION]);

    int current = await getCurrentParticipants();

    if (total == null || total <= 0)
      this.participantsTotal.setError("Invalid census size");
    else
      this.participantsTotal.setValue(total);

    if (current == null)
      this.participantsCurrent.setError("Invalid amount of participants");
    else
      this.participantsCurrent.setValue(total);

    stageParticipation();
    save();
    if (hasState) rebuildStates([ProcessStateTags.PARTICIPATION]);
  }

  stageParticipation() {
    if (participantsTotal.hasValue) {
      String total = this.participantsTotal.toString();
      processMetadata.value.meta[META_PROCESS_PARTICIPANTS_TOTAL] = total;
    }

    if (participantsCurrent.hasValue) {
      String current = this.participantsCurrent.toString();
      processMetadata.value.meta[META_PROCESS_PARTICIPANTS_CURRENT] = current;
    }
  }

  double get participation {
    if (!this.participantsTotal.hasValue || !this.participantsCurrent.hasValue)
      return 0.0;

    return this.participantsCurrent.value * 100 / this.participantsTotal.value;
  }

  updateDates() {
    if (!(processMetadata.value is ProcessMetadata)) return;

    //TODO subscribe to vochainModel changes
    if (vochainModel.referenceBlock.hasValue) {
      this.startDate.setValue(DateTime.now().add(vochainModel
          .getDurationUntilBlock(processMetadata.value.startBlock)));
      this.endDate.setValue(DateTime.now().add(
          vochainModel.getDurationUntilBlock(processMetadata.value.startBlock +
              processMetadata.value.numberOfBlocks)));
    } else {
      this.startDate.setError("Vochain is not in sync");
      this.endDate.setError("Vochain is not in sync");
    }
  }
}
