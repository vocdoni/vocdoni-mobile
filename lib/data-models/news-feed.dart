import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// NewsFeedPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
/// 
/// IMPORTANT: All **updates** on the state must call `notifyListeners()`
///
class NewsFeedPoolModel extends StateModel<List<NewsFeedModel>> {
  // TODO: Implement
}

/// NewsFeedModel encapsulates the relevant information of a Vocdoni NewsFeed.
/// This includes its metadata and the participation processes.
/// 
/// IMPORTANT: All **updates** on the state must call `notifyListeners()`
///
class NewsFeedModel extends StateModel<NewsFeedState> {
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
class NewsFeedState {
  // TODO: variables here
}
