import 'package:vocdoni/data-models/base-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// EntityPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
class EntityPoolModel extends DataModel {
  // TODO: Implement
}

/// EntityModel encapsulates the relevant information of a Vocdoni Entity.
/// This includes its metadata and the participation processes.
class EntityModel extends DataModel {
  // TODO: Implement

  @override
  Future<void> refresh() async {
    // TODO: Implement refetch of the metadata
    // TODO: Check the last time that data was fetched
    // TODO: Don't refetch if the IPFS hash is the same
  }
}
