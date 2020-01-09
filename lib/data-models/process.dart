import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/state-value.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// ProcessPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: Any **updates** on the own state must call `notifyListeners()` or use `setValue()`.
/// Updates on the children models will be handled by the object itself.
///
class ProcessPoolModel extends StateModel<List<ProcessModel>> {
  // TODO: Implement
}

/// ProcessModel encapsulates the relevant information of a Vocdoni Process.
/// This includes its metadata and the participation processes.
///
/// IMPORTANT: Any **updates** on the own state must call `notifyListeners()` or use `setValue()`.
/// Updates on the children models will be handled by the object itself.
///
class ProcessModel extends StateModel<ProcessState> {
  ProcessModel(ProcessMetadata meta) {
    final newValue = ProcessState();
    newValue.metadata.setValue(meta);
    newValue.isInCensus.setValue(false);
    this.setValue(newValue);
  }

  @override
  Future<void> refresh() async {
    // TODO: Implement refetch of the metadata
    // TODO: Check the last time that data was fetched
    // TODO: Don't refetch if the IPFS hash is the same
  }
}

// Use this class as a data container only. Any logic that updates the state
// should be defined above in the model class
class ProcessState {
  final StateValue<ProcessMetadata> metadata = StateValue<ProcessMetadata>();
  final StateValue<bool> isInCensus = StateValue<bool>();
  List<dynamic> choices = [];
}
