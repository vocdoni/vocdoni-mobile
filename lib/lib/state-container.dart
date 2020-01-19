import 'package:vocdoni/lib/state-base.dart';

/// Base class that wraps and manages **eventual data**, which can be still unresolved,
/// have an error, or have a non-null valid value.
///
/// **Use this class if you simply need to track eventual data within a stateful Widget
/// where you use `setState`**
///
class StateContainer<T> extends StateTracker<T> {
  /// Initializes the state with no value by default. If an argument is passed,
  /// the argument is set as the initial value.
  StateContainer([T initialValue]) {
    if (initialValue is T) this.setValue(initialValue);
  }
}
