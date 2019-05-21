import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocdoni/util/api.dart';

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("bootnodes")) return; // nothing to restore

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final dat = prefs.getStringList("bootnodes");
      if (!(dat is List)) {
        await prefs.setStringList("bootnodes", []);
        return;
      }
      final List<BootNode> deserializedBootNodes =
          dat.map((strNode) => BootNode.fromJson(jsonDecode(strNode))).toList();

      AppState newState = AppState()
        ..selectedIdentity = _state.value.selectedIdentity
        ..bootnodes = deserializedBootNodes;

      _state.add(newState);
    } catch (err) {
      print(err);
    }
  }

  Future loadBootNodes() async {
    try {
      final List<BootNode> bnList = await fetchBootNodes();
      await setBootNodes(bnList);
    } catch (err) {
      print("ERR: $err");
    }
  }

  Future<List<BootNode>> fetchBootNodes() async {
    final String strJsonBootnodes = await getBootNodes();
    final Map jsonBootnodes = jsonDecode(strJsonBootnodes);
    if (!(jsonBootnodes is Map)) throw ("Invalid bootnodes response");

    List<BootNode> bootnodes = List<BootNode>();
    for (String networkId in jsonBootnodes.keys) {
      if (!(jsonBootnodes[networkId] is List)) continue;
      (jsonBootnodes[networkId] as List).forEach((bootnode) {
        if (!(bootnode is Map)) return;

        String dvoteUri;
        String ethereumUri;
        if (bootnode["dvote"] is String) dvoteUri = bootnode["dvote"];
        if (bootnode["web3"] is String) ethereumUri = bootnode["web3"];
        BootNode bn =
            BootNode(networkId, dvoteUri: dvoteUri, ethereumUri: ethereumUri);
        bootnodes.add(bn);
      });
    }
    return bootnodes;
  }

  // Operations

  selectIdentity(int identityIdx) {
    AppState newState = AppState()
      ..selectedIdentity = identityIdx
      ..bootnodes = _state.value.bootnodes;

    _state.add(newState);

    // TODO: TRIGGER UPDATE
  }

  selectOrganization(int organizationIdx) {
    AppState newState = AppState()
      ..selectedIdentity = _state.value.selectedIdentity
      ..bootnodes = _state.value.bootnodes;

    _state.add(newState);
  }

  setBootNodes(List<BootNode> bootnodes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!(bootnodes is List<BootNode>)) throw ("Invalid bootnode list");
    final List<String> serializedData =
        bootnodes.map((node) => jsonEncode(node.toJson())).toList();
    await prefs.setStringList("bootnodes", serializedData);

    AppState newState = AppState()
      ..selectedIdentity = _state.value.selectedIdentity
      ..bootnodes = bootnodes;

    _state.add(newState);
  }
}

class AppState {
  int selectedIdentity = 0;
  List<BootNode> bootnodes = [];

  AppState({this.selectedIdentity = 0, this.bootnodes = const []});
}

class BootNode {
  final String networkId;
  final String dvoteUri;
  final String ethereumUri;

  BootNode(this.networkId, {this.dvoteUri, this.ethereumUri});

  BootNode.fromJson(Map<String, dynamic> json)
      : networkId = json['networkId'] ?? "",
        dvoteUri = json['dvoteUri'] ?? "",
        ethereumUri = json['ethereumUri'] ?? "";

  Map<String, dynamic> toJson() {
    return {
      'networkId': networkId,
      'dvoteUri': dvoteUri,
      'ethereumUri': ethereumUri
    };
  }
}
