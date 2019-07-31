import 'dart:io';
import 'package:vocdoni/data/generic.dart';
import 'package:vocdoni/util/api.dart';
import "dart:async";

// import 'package:vocdoni/util/singletons.dart';
import 'package:dvote/dvote.dart';

class IdentitiesBloc extends BlocComponent<List<Identity>> {
  final String _storageFile = IDENTITIES_STORE_FILE;

  IdentitiesBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    File fd;
    IdentitiesStore store;

    try {
      fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        return;
      }
    } catch (err) {
      print(err);
      throw "There was an error while accessing the local data";
    }

    try {
      final bytes = await fd.readAsBytes();
      store = IdentitiesStore.fromBuffer(bytes);
      state.add(store.items);
    } catch (err) {
      print(err);
      throw "There was an error processing the local data";
    }
  }

  @override
  Future<void> persist() async {
    // Gateway boot nodes
    try {
      File fd = File("${storageDir.path}/$_storageFile");
      IdentitiesStore store = IdentitiesStore();
      store.items.addAll(state.value);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw "There was an error while storing the changes";
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<Identity> data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

  /// Registers a new identity with an empty list of organizations
  Future create(String alias, String encryptionKey) async {
    if (!(alias is String) || alias.length < 2)
      throw ("Invalid alias");
    else if (!(encryptionKey is String) || encryptionKey.length < 2)
      throw ("Invalid encryptionKey");

    alias = alias.trim();
    if (super.current.where((item) => item.alias == alias).length > 0) {
      throw "The account already exists";
    }

    final mnemonic = await makeMnemonic();
    final privateKey = await privateKeyFromMnemonic(mnemonic);
    final publicKey = await publicKeyFromMnemonic(mnemonic);
    final address = await addressFromMnemonic(mnemonic);
    final encryptedMenmonic = await encryptString(mnemonic, encryptionKey);
    final encryptedPrivateKey = await encryptString(privateKey, encryptionKey);

    Identity newIdentity = Identity();
    newIdentity.alias = alias;
    newIdentity.identityId = publicKey;
    newIdentity.type = Identity_Type.ECDSA_SECP256k1;

    Key k = Key();
    k.type = Key_Type.SECP256K1;
    k.encryptedMnemonic = encryptedMenmonic;
    k.encryptedPrivateKey = encryptedPrivateKey;
    k.publicKey = publicKey;
    k.address = address;

    newIdentity.keys.add(k);

    // Add to existing, notify and store
    super.current.add(newIdentity);
    set(super.current);
  }

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
