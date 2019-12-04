enum DataStateStates {
  UNKNOWN, //Data is invalid, not initialized or not known
  BOOTING, //Data is invalid, not initialized or not known but updating it
  GOOD, //Data is valid
  REFRESHING, //Data is valid but updating it
  ERROR, // Data is invalid, it has been attempted to updated
  FAULTY //Data is valid, but it failed to update
}

class DataState<T> {
  DataStateStates state;
  DateTime lastGoodUpdate;
  DateTime lastErrorUpdate;
  String errorMessage;
  T currentValue;

  DataState() {
    state = DataStateStates.UNKNOWN;
  }

  void toUnknown() {
    currentValue = null;
    state = DataStateStates.UNKNOWN;
  }

  void toBooting() {
    currentValue = null;
    state = DataStateStates.BOOTING;
  }

  void toRefreshing() {
    state = DataStateStates.REFRESHING;
  }

  void toBootingOrRefreshing() {
    if (this.isValid)
      toRefreshing();
    else
      toBooting();
  }

  set value(T newValue) {
    currentValue = newValue;
    errorMessage = null;
    lastGoodUpdate = DateTime.now();
    state = DataStateStates.GOOD;
  }

  void toError(String message) {
    currentValue = null;
    errorMessage = message;
    lastErrorUpdate = DateTime.now();
    state = DataStateStates.ERROR;
  }

  void toFaulty(String message) {
    errorMessage = message;
    lastErrorUpdate = DateTime.now();
    state = DataStateStates.FAULTY;
  }

  void toErrorOrFaulty(String message) {
    if (this.isValid)
      this.toFaulty(message);
    else
      this.toError(message);
  }

  bool get isValid {
    return (state == DataStateStates.GOOD ||
        state == DataStateStates.REFRESHING ||
        state == DataStateStates.FAULTY);
  }

  bool get isNotValid {
    return isValid == false;
  }

  bool get isUpdating {
    return (state == DataStateStates.BOOTING ||
        state == DataStateStates.REFRESHING);
  }

  bool get hasError {
    return (state == DataStateStates.ERROR || state == DataStateStates.FAULTY);
  }

  T get value {
    return currentValue;
  }
}
