import 'package:flutter/foundation.dart';
import 'package:vocdoni/lib/state-value.dart';

/// Base class that wraps and manages **eventual data** that can involve
/// remote access, eventual exceptions and delayed completion.
///
/// It also provides notification capabilities, so that `provider` listeners
/// can rebuild upon any updates on it.
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
class StateModel<T> with ChangeNotifier, StateValue<T> {
  /*
  --------------------------------------------------------------------------
  INTERNAL STATE MANAGEMENT (inherited from StateValue)
  
  Track the evolution of the internal value, so any subscriber can
  retrieve the current status, display error messages, loading
  indicators or the value itself
  ---------------------------------------------------------------------------
  */

  @override
  setToLoading([String loadingMessage]) {
    super.setToLoading(loadingMessage);

    notifyListeners(); // Add provider notifications after the state is changed
  }

  @override
  setError(String error, {bool keepPreviousValue = false}) {
    super.setError(error, keepPreviousValue: keepPreviousValue);

    notifyListeners(); // Add provider notifications after the state is changed
  }

  @override
  setValue(T newValue) {
    super.setValue(newValue);

    notifyListeners(); // Add provider notifications after the state is changed
  }

  /*
  --------------------------------------------------------------------------
  EXTERNAL DATA MANAGEMENT

  Customize requests to read or write data from external sources
  ---------------------------------------------------------------------------
  */

  /// Read from the internal storage, update its own contents and notify the listeners.
  /// Tell all submodels to do the same.
  Future<void> readFromStorage() async {}

  /// Write the serializable model's data to the internal storage.
  /// Tell all submodels to do the same.
  Future<void> writeToStorage() async {}

  /// Fetch any relevent items that might have become outdated and notify
  /// the listeners. Care should be taken to avoid refetching when not really
  /// necessary.
  Future<void> refresh() async {}
}
