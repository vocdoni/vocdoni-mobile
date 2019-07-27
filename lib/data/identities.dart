import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "dart:convert";
import "dart:async";

import 'package:vocdoni/util/singletons.dart';
// import 'package:vocdoni/util/api.dart';
import 'package:dvote/dvote.dart';

/// STORAGE STRUCTURE
/// - SharedPreferences > "accounts" > String List > address (String)
/// - SecureStorage > {account-address} > { mnemonic, publicKey, alias }
/// - SharedPreferences > "{account-address}/organizations" > String List > { name, ... }

final secStore = new FlutterSecureStorage();

class IdentitiesBloc {
  BehaviorSubject<List<Identity>> _state =
      BehaviorSubject<List<Identity>>.seeded(List<Identity>());

  Observable<List<Identity>> get stream => _state.stream;
  List<Identity> get current => _state.value;

  Future restore() async {
    return readState();
  }

  /// Read and construct the data structures (without the private data/mnemonic)
  Future readState() async {
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

      List<String> orgs = [];
      if (prefs.containsKey("$addr/organizations")) {
        orgs = prefs.getStringList("$addr/organizations");
      }

      // Intentionally skip the mnemonic
      return Identity(
        publicKey: decoded["publicKey"],
        alias: decoded["alias"],
        // TODO: REMOVE
        mnemonic:
            "This Mnemonic Is Fake Because Is Not Encrypted This Mnemonic Is Fake Because Is Not Encrypted One Two",
        address: addr,
        organizations: orgs
            .where((String org) => org != null)
            .map((String org) => Entity.fromJson(jsonDecode(org)))
            .toList(),
      );
    }));
    identities = identities.where((item) => item != null).toList();

    _state.add(identities);
  }

  Future refreshSubscriptions() {
    // TODO: refresh for the selected identity
  }

  // Operations

  /// Registers a new identity with an empty list of organizations
  Future create(
      {String mnemonic, String publicKey, String address, String alias}) async {
    if (!(mnemonic is String))
      throw ("Invalid mnemonic");
    else if (!(publicKey is String))
      throw ("Invalid publicKey");
    else if (!(address is String))
      throw ("Invalid address");
    else if (!(alias is String) || alias.length < 2) throw ("Invalid alias");

    // ADD THE ADDRESS IN THE ACCOUNT INDEX
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> currentAddrs;
    if (prefs.containsKey("accounts")) {
      currentAddrs = prefs.getStringList("accounts");
      if (currentAddrs.length > 0) {
        // Check unique addr, alias
        await Future.wait(currentAddrs.map((addr) async {
          if (addr == address) throw ("The account already exists");

          final strIdent = await secStore.read(key: addr);
          final decoded = jsonDecode(strIdent);
          if (decoded is Map &&
              decoded["alias"] is String &&
              (decoded["alias"] as String).trim() == alias.trim()) {
            throw ("The account already exists");
          }
        }));

        currentAddrs.add(address);
        await prefs.setStringList("accounts", currentAddrs);
      } else {
        currentAddrs = [address];
        await prefs.setStringList("accounts", currentAddrs);
      }
    } else {
      currentAddrs = [address];
      await prefs.setStringList("accounts", currentAddrs);
    }

    // ADD A SERIALIZED WALLET FOR THE ADDRESS
    await secStore.write(
      key: address,
      value: json.encode({
        "mnemonic": mnemonic,
        "publicKey": publicKey,
        "alias": alias.trim()
      }),
    );

    // ADD AN EMPTY LIST OF ORGANIZATIONS
    await prefs.setStringList("$address/organizations", []);

    // Refresh state
    await readState();

    // Set the new identity as active
    appStateBloc.selectIdentity(currentAddrs.length - 1);
  }

  /// Register the given organization as a subscribtion of the currently selected identity
  subscribe(Entity newOrganization) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_state.value.length <= appStateBloc.current?.selectedIdentity)
      throw ("Invalid selectedIdentity: out of bounds");

    final address =
        prefs.getStringList("accounts")[appStateBloc.current.selectedIdentity];
    if (!(address is String)) throw ("Invalid account address");

    List<String> accountOrganizations = [];
    if (prefs.containsKey("$address/organizations")) {
      accountOrganizations = prefs.getStringList("$address/organizations");
    }

    final already = accountOrganizations.any((strEntity) {
      final org = Entity.fromJson(jsonDecode(strEntity));
      if (!(org is Entity)) return false;
      return org.entityId == newOrganization.entityId;
    });
    if (already) throw ("Already subscribed");

    accountOrganizations.add(json.encode(newOrganization.writeToJson()));
    await prefs.setStringList("$address/organizations", accountOrganizations);

    appStateBloc.selectOrganization(accountOrganizations.length - 1);

    // Refresh state
    await readState();

    // Fetch after the organization is registered
    await newsFeedsBloc.fetchEntityFeeds(newOrganization);
  }

  /// Remove the given organization from the currently selected identity's subscriptions
  unsubscribe(Entity org) {
    // TODO: PERSIST CHANGES
  }
}
