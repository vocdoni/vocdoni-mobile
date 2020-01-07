import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// VochainModel encapsulates the relevant information of a Vocdoni Vochain.
/// This includes its metadata and the participation processes.
/// 
/// IMPORTANT: All **updates** on the state must call `notifyListeners()`
///
class VochainModel extends StateModel<VochainState> {
  // TODO: Implement

  @override
  Future<void> refresh() async {
    // TODO: Implement refetch of the metadata
    // TODO: Check the last time that data was fetched
    
    // updateBlockHeight()
  }
}

// Use this class as a data container only. Any logic that updates the state
// should be defined above in the model class
class VochainState {
  // TODO: variables here
}
