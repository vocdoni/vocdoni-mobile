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
