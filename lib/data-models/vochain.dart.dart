import 'package:vocdoni/data-models/base-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// VochainModel encapsulates the relevant information of a Vocdoni Vochain.
/// This includes its metadata and the participation processes.
class VochainModel extends DataModel {
  // TODO: Implement
  @override
  Future<void> refresh() async {
    // TODO: Implement refetch of the metadata
    // TODO: Check the last time that data was fetched
    // TODO: Don't refetch if the IPFS hash is the same
  }
}
