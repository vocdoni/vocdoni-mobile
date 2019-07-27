import 'dart:io';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:vocdoni/util/api.dart';
// import 'package:dvote/models/dart/gateway.pb.dart';
import 'package:vocdoni/data/generic.dart';
import 'package:dvote/dvote.dart';

class AppStateBloc extends BlocComponent<AppState> {
  AppStateBloc() {
    state.add(AppState());
  }

  @override
  Future<void> restore() {
    // return readState();
  }

  @override
  Future<void> persist() {
    // TODO:
  }

  // Future restore() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   if (!prefs.containsKey("bootnodes")) return; // nothing to restore

  //   try {
  //     final dat = prefs.getStringList("bootnodes");
  //     if (!(dat is List)) {
  //       await prefs.setStringList("bootnodes", []);
  //       return;
  //     }
  //     final List<BootNode> deserializedBootNodes =
  //         dat.map((strNode) => BootNode.fromJson(jsonDecode(strNode))).toList();

  //     AppState newState = AppState()
  //       ..selectedIdentity = state.value.selectedIdentity
  //       ..bootnodes = deserializedBootNodes;

  //     state.add(newState);
  //   } catch (err) {
  //     print(err);
  //   }
  // }

  // Future loadBootNodes() async {
  //   try {
  //     final List<BootNode> bnList = await fetchBootNodes();
  //     await setBootNodes(bnList);
  //   } catch (err) {
  //     print("ERR: $err");
  //   }
  // }

  // Future<List<BootNode>> fetchBootNodes() async {
  //   final String strJsonBootnodes = await getBootNodes();
  //   final Map jsonBootnodes = jsonDecode(strJsonBootnodes);
  //   if (!(jsonBootnodes is Map)) throw ("Invalid bootnodes response");

  //   List<BootNode> bootnodes = List<BootNode>();
  //   for (String networkId in jsonBootnodes.keys) {
  //     if (!(jsonBootnodes[networkId] is List)) continue;
  //     (jsonBootnodes[networkId] as List).forEach((bootnode) {
  //       if (!(bootnode is Map)) return;

  //       BootNode bn = BootNode(
  //         networkId,
  //         dvoteUri: bootnode["dvote"] is String ? bootnode["dvote"] : null,
  //         ethereumUri: bootnode["web3"] is String ? bootnode["web3"] : null,
  //         publicKey: bootnode["pubKey"] is String ? bootnode["pubKey"] : null,
  //       );
  //       bootnodes.add(bn);
  //     });
  //   }
  //   return bootnodes;
  // }

  // // Operations

  // selectIdentity(int identityIdx) {
  //   AppState newState = AppState()
  //     ..selectedIdentity = identityIdx
  //     ..bootnodes = state.value.bootnodes;

  //   state.add(newState);

  //   // TODO: TRIGGER UPDATE
  // }

  // selectOrganization(int organizationIdx) {
  //   AppState newState = AppState()
  //     ..selectedIdentity = state.value.selectedIdentity
  //     ..bootnodes = state.value.bootnodes;

  //   state.add(newState);
  // }

  // setBootNodes(List<BootNode> bootnodes) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   if (!(bootnodes is List<BootNode>)) throw ("Invalid bootnode list");
  //   final List<String> serializedData =
  //       bootnodes.map((node) => jsonEncode(node.toJson())).toList();
  //   await prefs.setStringList("bootnodes", serializedData);

  //   AppState newState = AppState()
  //     ..selectedIdentity = state.value.selectedIdentity
  //     ..bootnodes = bootnodes;

  //   state.add(newState);
  // }
}

class AppState {
  int selectedIdentity = 0;
  /// All Gateways known to us, regardless of the entity
  List<Gateway> bootnodes = [];

  AppState({this.selectedIdentity = 0, this.bootnodes = const []});
}
