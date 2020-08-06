// --------------------------------------------------------------------------
// EXTERNAL DATA MANAGEMENT
// ---------------------------------------------------------------------------

/// Classes implementing this interface allow to refetch the current data from remote sources
abstract class ModelRefreshable {
  /// Fetch any internal items that might have become outdated and notify
  /// the listeners. Care should be taken to avoid refetching when not really
  /// necessary.
  Future<void> refresh({bool force = false});
}

/// Classes implementing this interface allow to read and write its internal data to
/// the global persistence objects
abstract class ModelPersistable {
  /// Read from the internal storage, update its own contents and notify the listeners.
  /// Tell all submodels to do the same.
  Future<void> readFromStorage();

  /// Write the serializable model's data to the internal storage.
  /// Tell all submodels to do the same.
  Future<void> writeToStorage();
}

/// Classes implementing this interface allow to clean values that correspond to a specific account
abstract class ModelCleanable {
  /// Set all variables containing ephemeral account-related data to null
  dynamic cleanEphemeral();
}
