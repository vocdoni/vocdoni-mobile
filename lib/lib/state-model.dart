import 'package:flutter/foundation.dart';
import 'package:vocdoni/lib/state-base.dart';

/// Base class that wraps and manages **eventual data**, which can be unresolved,
/// have an error or have a non-null valid value.
///
/// It also provides notification capabilities, so that `provider` listeners
/// can rebuild upon any updates on it.
///
/// **Use this class if you need to track eventual data and notify consumers about any changes**
///
/// STATE MODEL USAGE:
///
/// - Create a class to store your state
///   - Derive it from "StateModel"
///   - Add a global instance in `runApp` > `MultiProvider` > `providers[]`
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
class StateModel<T> extends StateTracker<T> with ChangeNotifier {
  /// Initializes the state with no value by default. If an argument is passed,
  /// the argument is set as the initial value.
  StateModel([T initialValue]) {
    if (initialValue is T) this.setValue(initialValue);
  }

  /*
  --------------------------------------------------------------------------
  INTERNAL STATE MANAGEMENT (overriden from StateTracker)
  
  Notify the changes of the internal value, so any subscriber can
  rebuild upon changes on the current value, error events or loading status
  ---------------------------------------------------------------------------
  */

  /// Sets the loading flag to true and an optional loading text.
  /// Notifies any change subscribers.
  /// Returns itself so further methods can be chained right after.
  @override
  StateModel setToLoading([String loadingMessage]) {
    super.setToLoading(loadingMessage);

    notifyListeners(); // Notify after the state is changed
    return this;
  }

  /// Sets the error message to the given value and toggles loading to false.
  /// Notifies any change subscribers.
  /// Optionally, allows to keep the current value, even if there is an error.
  /// Returns itself so further methods can be chained right after.
  @override
  StateModel setError(String error, {bool keepPreviousValue = false}) {
    super.setError(error, keepPreviousValue: keepPreviousValue);

    notifyListeners(); // Notify after the state is changed
    return this;
  }

  /// Sets the underlying value, clears any previous error and
  /// sets loading to false.
  /// Notifies any change subscribers.
  /// Returns itself so further methods can be chained right after.
  @override
  StateModel setValue(T newValue) {
    super.setValue(newValue);

    notifyListeners(); // Notify after the state is changed
    return this;
  }
}
