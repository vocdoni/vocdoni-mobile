enum DataStateStates {
  UNKNOWN, //Data is invalid, not initialized or not known
  BOOTING, //Data is invalid, not initialized or not known but updating it
  GOOD, //Data is valid
  REFRESHING, //Data is valid but updating it
  ERROR, // Data is invalid, it has been attempted to updated
  FAULTY //Data is valid, but it failed to update
}

class DataState {
  DataStateStates state = DataStateStates.UNKNOWN;
  DateTime lastGoodUpdate;
  DateTime lastErrorUpdate;
  String errorMessage;

  void toUnknown() {
    state = DataStateStates.UNKNOWN;
  }

  void toBooting() {
    state = DataStateStates.BOOTING;
  }

  void toRefreshing() {
    state = DataStateStates.REFRESHING;
  }

  void toBootingOrRefreshing() {
    if (this.isValid)
      state = DataStateStates.BOOTING;
    else {
      state = DataStateStates.REFRESHING;
    }
  }

  void toGood() {
    errorMessage = null;
    lastGoodUpdate = DateTime.now();
    state = DataStateStates.GOOD;
  }

  void toError(String message) {
    errorMessage = message;
    lastErrorUpdate = DateTime.now();
    state = DataStateStates.ERROR;
  }

  bool get isValid {
    return (state == DataStateStates.GOOD ||
        state == DataStateStates.REFRESHING || state ==DataStateStates.FAULTY);
  }

  bool get isNotValid {
    return !isValid;
  }

  bool get isUpdating {
    return (state == DataStateStates.BOOTING ||
        state == DataStateStates.REFRESHING);
  }

  bool get isError {
    return (state == DataStateStates.ERROR);
  }

}
