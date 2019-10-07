import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:vocdoni/controllers/account.dart';
import 'package:vocdoni/controllers/analtyics.dart';
import 'package:vocdoni/data/genericBloc.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/constants/settings.dart';

class AppStateBloc extends GenericBloc<AppState> {
  final String _storageFileBootNodes = BOOTNODES_STORE_FILE;

  AppStateBloc() {
    state.add(AppState());
  }

  // GENERIC OVERRIDES

  @override
  Future<void> init() async {
    await super.init();
  }

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    File fd;

    BootNodeGateways gwStore;

    // Gateway boot nodes
    try {
      fd = File("${storageDir.path}/$_storageFileBootNodes");
      if (await fd.exists()) {
        final bytes = await fd.readAsBytes();
        gwStore = BootNodeGateways.fromBuffer(bytes);
      } else {
        gwStore = BootNodeGateways();
      }
    } catch (err) {
      print(err);
      throw BlocRestoreError(
          "There was an error while accessing the local data");
    }

    // Assemble state object
    AppState newState = AppState()
      ..selectedIdentity = state.value.selectedIdentity
      ..bootnodes = gwStore;

    state.add(newState);

    
  }

   Future<void> load() async {
    await loadBootNodes().catchError((_) {
      print("Error: Unable to load the boot nodes");
    });

    syncBlockHeight();
  }


  @override
  Future<void> persist() async {
    try {
      // Gateway boot nodes
      File fd = File("${storageDir.path}/$_storageFileBootNodes");
      await fd.writeAsBytes(state.value.bootnodes.writeToBuffer());

      // TODO: Store authFailures and authThresholdDate
      print("TO DO: Store authFailures and authThresholdDate");
    } catch (err) {
      print(err);
      throw BlocPersistError("There was an error while storing the changes");
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
      final bnList = await getDefaultGatewaysInfo(NETWORK_ID);
      await setBootNodes(bnList);
    } catch (err) {
      print("ERR: $err");
    }
  }

  syncBlockHeight() async {
    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    try {
      int blockHeight = await getBlockHeight(dvoteGw);
      vochainBlockRef = blockHeight;
    } catch (e) {
      vochainBlockRef = 0;
    }
    vochainTimeRef = DateTime.now();
  }

 
  selectIdentity(int identityIdx) {
    AppState newState = AppState()
      ..selectedIdentity = identityIdx
      ..bootnodes = state.value.bootnodes;

    // do not use set(), because we don't need to persist anyting new
    state.add(newState);

    // Trigger updates elsewhere
    /*entitiesBloc
        .refreshFrom(identitiesBloc.value[identityIdx].peers.entities)
        .catchError((_) {
      print(
          "Error: Unable to refresh the entities from the newly selected identity");
    });*/

    account = new Account();
    analytics.setUser();
  }

  setBootNodes(BootNodeGateways bootnodes) async {
    if (!(bootnodes is BootNodeGateways))
      throw Exception("Invalid bootnode list");

    AppState newState = AppState()
      ..selectedIdentity = state.value.selectedIdentity
      ..bootnodes = bootnodes;

    set(newState);
  }

  Future trackAuthAttemp(bool successful) async {
    final newState = value;
    var now = DateTime.now();
    if (successful) {
      newState.authFailures = 0;
    } else {
      newState.authFailures++;
      final seconds = pow(2, newState.authFailures);
      now.add(Duration(seconds: seconds));
    }
    newState.authThresholdDate = now;
    await set(newState);
  }
}

class AppState {
  /// Index of the currently active identity
  int selectedIdentity = 0;

  /// All Gateways known to us, regardless of the entity.
  BootNodeGateways bootnodes;

  /// How many failed auth attempts happened since the last
  /// successful one.
  int authFailures = 0;

  /// Date after which a new auth attempt can be made
  DateTime authThresholdDate = DateTime.now();

  AppState({this.selectedIdentity = 0, this.bootnodes});

  /*static GatewayInfo getInitialBootnode() {
    GatewayInfo node = new GatewayInfo();
    //node.mergeFromJson(bootNodeJson);
    node.web3 = 'https://gwdev1.vocdoni.net/web3';
    return node;
  }

  static String bootNodeJson = ''' {
      "web3":[
         {
            "uri":"https://gwdev1.vocdoni.net/web3"
         },
         {
            "uri":"https://gwdev2.vocdoni.net/web3"
         }
      ],
      "dvote":[
         {
            "uri":"wss://gwdev1.vocdoni.net/dvote",
            "apis":[
               "file",
               "vote",
               "census"
            ],
            "pubKey":"02325f284f50fa52d53579c7873a480b351cc20f7780fa556929f5017283ad2449"
         },
         {
            "uri":"wss://gwdev2.vocdoni.net/dvote",
            "apis":[
               "file",
               "vote",
               "census"
            ],
            "pubKey":"0381290a9b7fabe99c24d8edcf4746859f17ee8e6099288fcf9170c356545fcac0"
         }
      ]
   }''';
   */
}
