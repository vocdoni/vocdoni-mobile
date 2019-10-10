enum DataStateStates { UNKNOWN, BOOTING, REFRESHING, GOOD, ERROR }

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
  
}
