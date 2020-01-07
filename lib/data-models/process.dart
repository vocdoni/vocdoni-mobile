import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// ProcessPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
/// 
/// IMPORTANT: All **updates** on the state must call `notifyListeners()`
///
class ProcessPoolModel extends StateModel<List<ProcessModel>> {
  // TODO: Implement
}

/// ProcessModel encapsulates the relevant information of a Vocdoni Process.
/// This includes its metadata and the participation processes.
/// 
/// IMPORTANT: All **updates** on the state must call `notifyListeners()`
///
class ProcessModel extends StateModel<ProcessState> {
  // TODO: Implement

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
  // TODO: variables here
}
