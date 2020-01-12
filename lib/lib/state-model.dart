import 'package:vocdoni/lib/state-value.dart';

/// Base class that wraps and manages **eventual data**, which can be still unresolved,
/// have an error, or have a non-null valid value.
///
/// It also provides notification capabilities, so that `provider` listeners
/// can rebuild upon any updates on it.
///
/// **Use this class if you need to track remote data loading, manage persistence and notify UI widgets.**
///
/// STATE MODEL USAGE:
///
/// - Create a class to store your state
///   - Derive it from "StateModel"
///   - Add a global instance in `runApp` > `MultiProvider` > `providers[]`
///   - Using them as a local data manager is possible but persistence
///     should only be handled on the **global** ones
/// - Collections
///   - Use standard classes to contain an element's data
///   - Use "pool" versions to contain an array of standard instances
///   - "Consume" from the nearest provider to the actual data
/// - Storage
///   - A data model is the source of truth
///   - Persistence is made upon request of the data model
///   - Data initialization is done from the data model perspective
///   - Operations are made on the data model instance
/// - Provider
///   - Provide an instance or your data models to the root of the widget tree
///   - Use MultiProvider if you have many
///   - Consume them using `Provider.of` of the `Consume` widget
///
/// More info:
/// - https://pub.dev/packages/provider
/// - https://www.youtube.com/watch?v=d_m5csmrf7I
///
class StateModel<T> extends StateValue<T> {
  /*
  --------------------------------------------------------------------------
  EXTERNAL DATA MANAGEMENT

  Customize requests to read or write data from external sources
  ---------------------------------------------------------------------------
  */

  /// Read from the internal storage, update its own contents and notify the listeners.
  /// Tell all submodels to do the same.
  /// Override it to suit your needs.
  Future<void> readFromStorage() {
    throw Exception("readFromStorage is not available on this class");
  }

  /// Write the serializable model's data to the internal storage.
  /// Tell all submodels to do the same.
  /// Override it to suit your needs.
  Future<void> writeToStorage() {
    throw Exception("writeToStorage is not available on this class");
  }

  /// Fetch any relevent items that might have become outdated and notify
  /// the listeners. Care should be taken to avoid refetching when not really
  /// necessary.
  /// Override it to suit your needs.
  Future<void> refresh() {
    throw Exception("refresh is not available on this class");
  }
}
