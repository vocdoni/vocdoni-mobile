import 'package:rxdart/rxdart.dart';

class AppStateBloc {
  BehaviorSubject<AppState> _state =
      BehaviorSubject<AppState>.seeded(AppState());

  Observable<AppState> get stream => _state.stream;
  AppState get current => _state.value;

  // Constructor
  AppStateBloc() {
    _state.add(AppState());
  }

  Future restore() async {
    // TODO: Fetch the last selected identity
    // TODO: Exampe: https://github.com/AppleEducate/flutter_login/blob/master/lib/data/models/auth.dart
  }

  // Operations

  selectIdentity(int identityIdx) {
    _state
        .add(AppState(selectedIdentity: identityIdx, selectedOrganization: 0));
  }

  selectOrganization(int organizationIdx) {
    _state.add(AppState(
        selectedIdentity: _state.value.selectedIdentity,
        selectedOrganization: organizationIdx));
  }
}

class AppState {
  int selectedIdentity = 0;
  int selectedOrganization = 0;

  AppState({this.selectedIdentity = 0, this.selectedOrganization = 0});
}
