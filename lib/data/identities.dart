import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "dart:convert";

///
/// STORAGE STRUCTURE
/// - SharedPreferences > "accounts" > String List > address (String)
/// - SecureStorage > {account-address} > { mnemonic, publicKey, alias }
/// - SharedPreferences > "{account-address}-organizations" > String List > { name, ... }

final secStore = new FlutterSecureStorage();

class IdentitiesBloc {
  BehaviorSubject<List<Identity>> _state =
      BehaviorSubject<List<Identity>>.seeded(List<Identity>());

  Observable<List<Identity>> get stream => _state.stream;
  List<Identity> get current => _state.value;

  Future restore() async {
    return fetchState();
  }

  Future fetchState() async {
    // Read and construct the data structures (without the private data/mnemonic)

    List<Identity> identities = List<Identity>();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey("accounts")) return; // nothing to fetch

    List<String> accounts = prefs.getStringList("accounts");

    identities = await Future.wait(accounts.map((addr) async {
      String str = await secStore.read(key: addr);
      if (str == null) {
        print("WARNING: Data for $addr is empty");
        return null;
      }
      final decoded = jsonDecode(str);
      if (!(decoded is Map)) {
        return null;
      } else if (!(decoded["publicKey"] is String) ||
          !(decoded["alias"] is String)) {
        return null;
      }

      // Intentionally skip the mnemonic
      return Identity(
        publicKey: decoded["publicKey"],
        alias: decoded["alias"],
        mnemonic: null,
        address: addr,
      );
    }));
    identities = identities.where((item) => item != null).toList();

    // TODO: No organizations fetched yet

    _state.add(identities);
  }

  // Operations

  /// Registers a new identity with an empty list of organizations
  create(
      {String mnemonic, String publicKey, String address, String alias}) async {
    if (!(mnemonic is String))
      throw ("Invalid mnemonic");
    else if (!(publicKey is String))
      throw ("Invalid publicKey");
    else if (!(address is String))
      throw ("Invalid address");
    else if (!(alias is String)) throw ("Invalid alias");

    // ADD THE ADDRESS IN THE ACCOUNT INDEX
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey("accounts")) {
      final currentAddrs = prefs.getStringList("accounts");
      if (currentAddrs.length > 0) {
        if (currentAddrs.indexWhere((addr) => addr == address) >= 0 ||
            (await secStore.read(key: address)) != null) {
          throw ("The account already exists");
        } else {
          currentAddrs.add(address);
          prefs.setStringList("accounts", currentAddrs);
        }
      } else {
        prefs.setStringList("accounts", [address]);
      }
    } else {
      prefs.setStringList("accounts", [address]);
    }

    // ADD A SERIALIZED WALLET FOR THE ADDRESS
    await secStore.write(
      key: address,
      value: json.encode(
          {"mnemonic": mnemonic, "publicKey": publicKey, "alias": alias}),
    );

    // ADD AN EMPTY LIST OF ORGANIZATIONS
    await prefs.setStringList("$address-organizations", []);

    fetchState();
  }

  /// Register the given organization as a subscribtion of the currently selected identity
  subscribe(Organization newOrganization) async {
    // TODO: PERSIST CHANGES
    print("TODO: REGISTER ORGANIZATION: $newOrganization");

    // TODO: appStateBloc.selectOrganization(n);
  }

  /// Remove the given organization from the currently selected identity's subscriptions
  unsubscribe(Organization org) {
    // TODO: PERSIST CHANGES
  }
}

class Identity {
  final String alias;
  final String mnemonic;
  final String publicKey;
  final String address;

  Identity({this.alias, this.publicKey, this.mnemonic, this.address});
}

class Organization {
  final String name;
  final String resolverAddress;
  final String entityId;
  final String networkId;
  final List<String> entryPoints;

  Organization(
      {this.name,
      this.resolverAddress,
      this.entityId,
      this.networkId,
      this.entryPoints});

  // Organization.fromJson(Map<String, dynamic> json) : name = json['name'];

  // Map<String, dynamic> toJson() => {
  //       'name': name,
  //     };
}
