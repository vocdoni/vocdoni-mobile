/// Base class that wraps and manages **eventual data** that can involve
/// remote fetching, eventual exceptions and delayed completion.
///
class StateValue<T> {
  bool _loading = false;
  String _loadingMessage; // optional

  String _errorMessage; // If not null, then _currentValue is not valid
  DateTime _lastError;

  T _currentValue;
  DateTime _lastUpdated;

  /// Sets the loading flag to true and an optional loading text
  setToLoading([String loadingMessage]) {
    _loading = true;
    if (loadingMessage is String && loadingMessage.length > 0) {
      _loadingMessage = loadingMessage;
    }

    _errorMessage = null;
  }

  /// Sets the error message to the given value and toggles loading to false.
  /// Optionally, allows to keep the current value, even if there is an error.
  setError(String error, {bool keepPreviousValue = false}) {
    _errorMessage = error;
    _lastError = DateTime.now();

    _loading = false;
    _loadingMessage = null;

    if (keepPreviousValue != true) {
      _currentValue = null;
      _lastUpdated = null;
    }
  }

  /// Sets the underlying value, clears any previous error and
  /// sets loading to false
  setValue(T value) {
    _currentValue = value;
    _lastUpdated = DateTime.now();

    _loading = false;
    _loadingMessage = null;

    _errorMessage = null;
    _lastError = null;
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
}
