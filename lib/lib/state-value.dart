import 'package:flutter/foundation.dart';
import 'package:vocdoni/lib/state-tracker-base.dart';

/// Base class that wraps and manages **eventual data**, which can be still unresolved,
/// have an error, or have a non-null valid value.
///
/// It also provides notification capabilities, so that `provider` listeners
/// can rebuild upon any updates on it.
///
/// **Use this class if you need to track eventual data and notify consumers about any changes**
///
class StateValue<T> extends StateTrackerBase<T> with ChangeNotifier {
  /// Initializes the state with no value by default. If an argument is passed,
  /// the argument is set as the initial value.
  StateValue([T initialValue]) {
    if (initialValue is T) this.setValue(initialValue);
  }

  /*
  --------------------------------------------------------------------------
  INTERNAL STATE MANAGEMENT (overriden from StateTrackerBase)
  
  Notify the changes of the internal value, so any subscriber can
  rebuild upon changes on the current value, error events or loading status
  ---------------------------------------------------------------------------
  */

  /// Sets the loading flag to true and an optional loading text.
  /// Notifies any change subscribers.
  /// Returns itself so further methods can be chained right after.
  @override
  StateValue setToLoading([String loadingMessage]) {
    super.setToLoading(loadingMessage);

    notifyListeners(); // Notify after the state is changed
    return this;
  }

  /// Sets the error message to the given value and toggles loading to false.
  /// Notifies any change subscribers.
  /// Optionally, allows to keep the current value, even if there is an error.
  /// Returns itself so further methods can be chained right after.
  @override
  StateValue setError(String error, {bool keepPreviousValue = false}) {
    super.setError(error, keepPreviousValue: keepPreviousValue);

    notifyListeners(); // Notify after the state is changed
    return this;
  }

  /// Sets the underlying value, clears any previous error and
  /// sets loading to false.
  /// Notifies any change subscribers.
  /// Returns itself so further methods can be chained right after.
  @override
  StateValue setValue(T newValue) {
    super.setValue(newValue);

    notifyListeners(); // Notify after the state is changed
    return this;
  }
}
