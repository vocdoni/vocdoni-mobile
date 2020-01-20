// --------------------------------------------------------------------------
// INTERNAL DATA TRACKING
// ---------------------------------------------------------------------------

/// Base class that wraps and manages **eventual data**, which can be still unresolved,
/// have an error, or have a non-null valid value.
///
/// Use this class if you need to track eventual data, and be able to check its status explicitly
/// from your code using `hasValue`, `hasError` and `isLoading`.
///
class StateContainer<T> {
  bool _loading = false;
  String _loadingMessage; // optional

  String _errorMessage; // If not null, then _currentValue is not valid
  DateTime _lastError;

  T _currentValue;
  DateTime _lastUpdated;

  int _recentSecondsThreshold =
      10; // Amount of seconds before `isFresh` returns false

  /// Initializes the state with no value by default. If an argument is passed,
  /// the argument is set as the initial value.
  StateContainer([T initialValue]) {
    if (initialValue is T) this.load(initialValue);
  }

  /// Sets the loading flag to true and an optional loading text.
  /// Returns itself so further methods can be chained right after.
  StateContainer setToLoading([String loadingMessage]) {
    _loading = true;
    if (loadingMessage is String && loadingMessage.length > 0) {
      _loadingMessage = loadingMessage;
    }

    _errorMessage = null;
    return this;
  }

  /// Sets the error message to the given value and toggles loading to false.
  /// Optionally, allows to keep the current value, even if there is an error.
  /// Returns itself so further methods can be chained right after.
  StateContainer setError(String error, {bool keepPreviousValue = false}) {
    _errorMessage = error;
    _lastError = DateTime.now();

    _loading = false;
    _loadingMessage = null;

    if (keepPreviousValue != true) {
      _currentValue = null;
      _lastUpdated = null;
    }
    return this;
  }

  /// Sets the underlying value, clears any previous error and
  /// sets loading to false.
  /// Returns itself so further methods can be chained right after.
  StateContainer setValue(T value) {
    _currentValue = value;
    _lastUpdated = DateTime.now();

    _loading = false;
    _loadingMessage = null;

    _errorMessage = null;
    _lastError = null;
    return this;
  }

  /// Immediately sets the given value and unlike `setValue`, does not update the modification date or any error message.
  /// Use `load()` if you want `model.isFresh` to return `false` right after.
  /// Returns itself so further methods can be chained right after.
  StateContainer load(T value) {
    _currentValue = value;

    _loading = false;
    _loadingMessage = null;

    return this;
  }

  /// By default `isFresh` returns `false` 10 seconds after the value is set.
  /// Alter the recency threshold with a new value.
  /// Returns itself so further methods can be chained right after.
  withFreshness(int seconds) {
    if (seconds < 0) throw Exception("The amount of seconds must be positive");

    this._recentSecondsThreshold = seconds;
    return this;
  }

  /// Returns true if the loading flag is currently active
  bool get isLoading {
    return _loading;
  }

  /// Returns the optional loading message string
  String get loadingMessage {
    return _loadingMessage;
  }

  /// Returns true if an error message is currently set
  bool get hasError {
    return _errorMessage != null;
  }

  /// Returns the last error message defined
  String get errorMessage {
    return _errorMessage;
  }

  /// Returns true if a valid value is registered and no error has
  /// cleared it
  bool get hasValue {
    if (_errorMessage != null) return true;
    return _lastUpdated != null && _currentValue is T;
  }

  /// Provides the current value, if there is any
  T get value {
    return _currentValue;
  }

  /// Returns the last successful update
  DateTime get lastUpdated {
    return _lastUpdated;
  }

  /// Returns the timestamp of the last error encountered
  DateTime get lastError {
    return _lastError;
  }

  /// Returns true if a valid value was set less than 10 seconds ago
  bool get isFresh {
    return hasValue &&
        _lastUpdated is DateTime &&
        DateTime.now().difference(_lastUpdated) <
            Duration(seconds: this._recentSecondsThreshold);
  }
}
