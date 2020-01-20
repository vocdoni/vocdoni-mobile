// --------------------------------------------------------------------------
// EXTERNAL DATA MANAGEMENT
// ---------------------------------------------------------------------------

/// Classes implementing this interface allow to refetch the current data from remote sources
abstract class StateRefreshable {
  /// Fetch any internal items that might have become outdated and notify
  /// the listeners. Care should be taken to avoid refetching when not really
  /// necessary.
  Future<void> refresh([bool force = false]);
}

/// Classes implementing this interface allow to read and write its internal data to
/// the global persistence objects
abstract class StatePersistable {
  /// Read from the internal storage, update its own contents and notify the listeners.
  /// Tell all submodels to do the same.
  Future<void> readFromStorage();

  /// Write the serializable model's data to the internal storage.
  /// Tell all submodels to do the same.
  Future<void> writeToStorage();
}

// --------------------------------------------------------------------------
// INTERNAL DATA TRACKING
// ---------------------------------------------------------------------------

/// State manager that wraps a value, allows to track whether data is being awaited,
/// whether an error occurred or whether a non-null value is present.
class StateTracker<T> {
  bool _loading = false;
  String _loadingMessage; // optional

  String _errorMessage; // If not null, then _currentValue is not valid
  DateTime _lastError;

  T _currentValue;
  DateTime _lastUpdated;

  int _recentSecondsThreshold =
      10; // Amount of seconds before `isFresh` returns false

  /// Sets the loading flag to true and an optional loading text.
  /// Returns itself so further methods can be chained right after.
  StateTracker setToLoading([String loadingMessage]) {
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
  StateTracker setError(String error, {bool keepPreviousValue = false}) {
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
  StateTracker setValue(T value) {
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
  StateTracker load(T value) {
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
