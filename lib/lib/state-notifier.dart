import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/lib/state-container.dart';

// --------------------------------------------------------------------------
// GLOBAL DATA TRACKING
// ---------------------------------------------------------------------------

/// Base class that wraps and manages **eventual data**, which can be unresolved,
/// have an error or have a non-null valid value.
///
/// It also provides notification capabilities, so that `ChangeNotifierProvider.value()` widgets can listen
/// and rebuild upon any updates on it.
///
/// **Use this class if you need to track eventual data and notify consumers about any changes**
///
/// STATE MODEL USAGE:
///
/// - Create a class to store your state
///   - Derive it from "StateNotifier"
///   - Add a global instance in `runApp` > `MultiProvider` > `providers[]`
/// - Collections
///   - Use standard classes to contain an element's data
///   - Use "pool" versions to contain an array of standard instances
///   - "Consume" from the nearest provider to the actual data
/// - Storage
///   - StateNotifier's are the source of truth
///   - Persistence is made upon request of the StateNotifier
///   - Data initialization is done from the StateNotifier perspective
///   - Operations are made on the StateNotifier subclass
/// - Provider
///   - Provide a global instance of your StateNotifier's to the root of the widget tree
///   - Use MultiProvider if you have more than one
///   - Use global (pool) models using `Consume` or `Provider.of` within a widget or directly use the global pools from `singletons.dart`
///   - Use standard models using `ChangeNotifierProvider.value()` within a widget
///
/// More info:
/// - https://pub.dev/packages/provider
/// - https://www.youtube.com/watch?v=d_m5csmrf7I
///
class StateNotifier<T> extends StateContainer<T> with ChangeNotifier {
  /// Initializes the state with no value by default. If an argument is passed,
  /// the argument is set as the initial value.
  StateNotifier([T initialValue]) {
    if (initialValue is T) this.load(initialValue);
  }

  /*
  --------------------------------------------------------------------------
  INTERNAL STATE MANAGEMENT (overriden from StateContainer)
  
  Notify the changes of the internal value, so any subscriber can
  rebuild upon changes on the current value, error events or loading status
  ---------------------------------------------------------------------------
  */

  /// Sets the loading flag to true and an optional loading text.
  /// Notifies any change subscribers.
  /// Returns itself so further methods can be chained right after.
  @override
  StateNotifier setToLoading([String loadingMessage]) {
    super.setToLoading(loadingMessage);

    // Notify after the state is changed
    this.notify();
    return this;
  }

  /// Sets the error message to the given value and toggles loading to false.
  /// Notifies any change subscribers.
  /// Optionally, allows to keep the current value, even if there is an error.
  /// Returns itself so further methods can be chained right after.
  @override
  StateNotifier setError(String error, {bool keepPreviousValue = false}) {
    super.setError(error, keepPreviousValue: keepPreviousValue);

    // Notify after the state is changed
    this.notify();
    return this;
  }

  /// Sets the underlying value, clears any previous error and
  /// sets loading to false.
  /// Notifies any change subscribers.
  /// Returns itself so further methods can be chained right after.
  @override
  StateNotifier setValue(T newValue) {
    super.setValue(newValue);

    // Notify after the state is changed
    this.notify();
    return this;
  }

  /// Explicitly emits a change notification event to the listeners
  StateNotifier notify() {
    Timer(Duration(milliseconds: 1), () => this.notifyListeners());
    return this;
  }
}
