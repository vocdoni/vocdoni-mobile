import 'dart:io';
import 'dart:async';
import 'package:vocdoni/util/api.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:dvote/models/dart/gateway.pb.dart';
import 'package:vocdoni/data/generic.dart';
import 'package:dvote/dvote.dart';

class AppStateBloc extends BlocComponent<AppState> {
  final String _storageFileBootNodes = BOOTNODES_STORE_FILE;

  AppStateBloc() {
    state.add(AppState());
  }

  // GENERIC OVERRIDES

  @override
  Future<void> init() async {
    await super.init();

    // POST-BOOTSTRAP ACTIONS
    Timer(Duration(seconds: 2), () {
      loadBootNodes().catchError((_) {
        print("Error: Unable to load the boot nodes");
      });
    });
  }

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    File fd;
    GatewaysStore gwStore;

    // Gateway boot nodes
    try {
      fd = File("${storageDir.path}/$_storageFileBootNodes");
      if (await fd.exists()) {
        final bytes = await fd.readAsBytes();
        gwStore = GatewaysStore.fromBuffer(bytes);
      } else {
        gwStore = GatewaysStore();
      }
    } catch (err) {
      print(err);
      throw "There was an error while accessing the local data";
    }

    // Assemble state object
    AppState newState = AppState()
      ..selectedIdentity = state.value.selectedIdentity
      ..bootnodes = gwStore.bootnodes;

    set(newState);
  }

  @override
  Future<void> persist() async {
    // Gateway boot nodes
    try {
      File fd = File("${storageDir.path}/$_storageFileBootNodes");
      GatewaysStore store = GatewaysStore();
      store.bootnodes.addAll(state.value.bootnodes);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw "There was an error while storing the changes";
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(AppState data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

  Future loadBootNodes() async {
    try {
      final bnList = await getBootNodes();
      await setBootNodes(bnList);
    } catch (err) {
      print("ERR: $err");
    }
  }

  // Operations

  selectIdentity(int identityIdx) {
    AppState newState = AppState()
      ..selectedIdentity = identityIdx
      ..bootnodes = state.value.bootnodes;

    // do not use set(), because we don't need to persist anyting new
    state.add(newState);

    // TODO: TRIGGER UPDATE ELSEWHERE
  }

  setBootNodes(List<Gateway> bootnodes) async {
    if (!(bootnodes is List<Gateway>)) throw "Invalid bootnode list";

    AppState newState = AppState()
      ..selectedIdentity = state.value.selectedIdentity
      ..bootnodes = bootnodes;

    set(newState);
  }
}

class AppState {
  /// Index of the currently active identity
  int selectedIdentity = 0;

  /// All Gateways known to us, regardless of the entity.
  /// `gateway.meta["networkId"]` should contain the ID of the Ethereum network, so
  /// it can be filtered.
  List<Gateway> bootnodes = [];

  AppState({this.selectedIdentity = 0, this.bootnodes = const []});
}
