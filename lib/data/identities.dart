import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocdoni/data/generic.dart';
import "dart:async";

import 'package:vocdoni/util/singletons.dart';
import 'package:dvote/dvote.dart';

final secStore = new FlutterSecureStorage();

class IdentitiesBloc extends BlocComponent<List<Identity>> {
  IdentitiesBloc() {
    state.add([]);
  }

  @override
  Future<void> restore() {
    return readState();
  }

  @override
  Future<void> persist() {
    // TODO:
  }

  @override
  void set(List<Identity> data) {
    // TODO:
  }

  /// Read and construct the data structures
  Future readState() async {
    File fd;
    IdentitiesStore store;

    try {
      fd = File(IDENTITIES_STORE_PATH);
      if (!(await fd.exists())) {
        super.state.add([]);
        return;
      }
    } catch (err) {
      print(err);
      super.state.add([]);
      throw "There was an error while accessing the local data";
    }

    try {
      final bytes = await fd.readAsBytes();
      store = IdentitiesStore.fromBuffer(bytes);
      super.state.add(store.identities);
    } catch (err) {
      print(err);
      super.state.add([]);
      throw "There was an error processing the local data";
    }
  }

  // // Operations

  // /// Registers a new identity with an empty list of organizations
  // Future create(
  //     {String mnemonic, String publicKey, String address, String alias}) async {
  //   if (!(mnemonic is String))
  //     throw ("Invalid mnemonic");
  //   else if (!(publicKey is String))
  //     throw ("Invalid publicKey");
  //   else if (!(address is String))
  //     throw ("Invalid address");
  //   else if (!(alias is String) || alias.length < 2) throw ("Invalid alias");

  //   // ADD THE ADDRESS IN THE ACCOUNT INDEX
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   List<String> currentAddrs;
  //   if (prefs.containsKey("accounts")) {
  //     currentAddrs = prefs.getStringList("accounts");
  //     if (currentAddrs.length > 0) {
  //       // Check unique addr, alias
  //       await Future.wait(currentAddrs.map((addr) async {
  //         if (addr == address) throw ("The account already exists");

  //         final strIdent = await secStore.read(key: addr);
  //         final decoded = jsonDecode(strIdent);
  //         if (decoded is Map &&
  //             decoded["alias"] is String &&
  //             (decoded["alias"] as String).trim() == alias.trim()) {
  //           throw ("The account already exists");
  //         }
  //       }));

  //       currentAddrs.add(address);
  //       await prefs.setStringList("accounts", currentAddrs);
  //     } else {
  //       currentAddrs = [address];
  //       await prefs.setStringList("accounts", currentAddrs);
  //     }
  //   } else {
  //     currentAddrs = [address];
  //     await prefs.setStringList("accounts", currentAddrs);
  //   }

  //   // ADD A SERIALIZED WALLET FOR THE ADDRESS
  //   await secStore.write(
  //     key: address,
  //     value: json.encode({
  //       "mnemonic": mnemonic,
  //       "publicKey": publicKey,
  //       "alias": alias.trim()
  //     }),
  //   );

  //   // ADD AN EMPTY LIST OF ORGANIZATIONS
  //   await prefs.setStringList("$address/organizations", []);

  //   // Refresh state
  //   await readState();

  //   // Set the new identity as active
  //   appStateBloc.selectIdentity(currentAddrs.length - 1);
  // }

  // /// Register the given organization as a subscribtion of the currently selected identity
  // subscribe(Entity newOrganization) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   if (super.state.value.length <= appStateBloc.current?.selectedIdentity)
  //     throw ("Invalid selectedIdentity: out of bounds");

  //   final address =
  //       prefs.getStringList("accounts")[appStateBloc.current.selectedIdentity];
  //   if (!(address is String)) throw ("Invalid account address");

  //   List<String> accountOrganizations = [];
  //   if (prefs.containsKey("$address/organizations")) {
  //     accountOrganizations = prefs.getStringList("$address/organizations");
  //   }

  //   final already = accountOrganizations.any((strEntity) {
  //     final org = Entity.fromJson(jsonDecode(strEntity));
  //     if (!(org is Entity)) return false;
  //     return org.entityId == newOrganization.entityId;
  //   });
  //   if (already) throw ("Already subscribed");

  //   accountOrganizations.add(json.encode(newOrganization.writeToJson()));
  //   await prefs.setStringList("$address/organizations", accountOrganizations);

  //   appStateBloc.selectOrganization(accountOrganizations.length - 1);

  //   // Refresh state
  //   await readState();

  //   // Fetch after the organization is registered
  //   await newsFeedsBloc.fetchEntityFeeds(newOrganization);
  // }

  // /// Remove the given organization from the currently selected identity's subscriptions
  // unsubscribe(Entity org) {
  //   // TODO: PERSIST CHANGES
  // }
}
