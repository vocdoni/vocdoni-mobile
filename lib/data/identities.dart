import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:flutter/material.dart';
import 'package:vocdoni/data/generic.dart';
import 'package:vocdoni/util/api.dart';
import "dart:async";

import 'package:vocdoni/util/singletons.dart';

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
      throw FlutterError("Invalid alias");
    else if (!(encryptionKey is String) || encryptionKey.length < 2)
      throw FlutterError("Invalid encryptionKey");

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

    dvote.Key k = dvote.Key();
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

  Identity get currentIdentity {
    return identitiesBloc.current[appStateBloc.current.selectedIdentity];
  }

  bool isSubscribed(Identity identity, Entity entity) {
    return identity.peers.entities.any((existingEntitiy) {
      return entity.entityId == existingEntitiy.entityId;
    });
  }

  /// Register the given organization as a subscribtion of the currently selected identity
  subscribe(Entity newEntity) async {
    if (super.state.value.length <= appStateBloc.current?.selectedIdentity)
      throw FlutterError("Invalid selectedIdentity: out of bounds");

    // Add the entity to the global registry if it does not exist
    await entitiesBloc.add(newEntity);

    // Add the summary of the entity to the current identity
    final currentIdentities = identitiesBloc.current;

    final currentIdentity =
        currentIdentities[appStateBloc.current.selectedIdentity];
    if (!(currentIdentity is List<Identity>))
      throw FlutterError("The current account is invalid");

    final already = currentIdentity.peers.entities.any((entity) {
      return entity.entityId == newEntity.entityId;
    });
    if (already)
      throw FlutterError("You are already subscribed to this entity");

    EntitySummary es = EntitySummary();
    es.entityId = newEntity.entityId;
    es.resolverAddress = newEntity.contracts.resolverAddress;
    es.networkId = newEntity.contracts.networkId;
    es.entryPoints.addAll(newEntity.meta["entryPoints"] ?? []);

    // Update existing identities
    Identity_Peers newPeers = Identity_Peers();
    newPeers.entities.addAll(currentIdentity.peers.entities.followedBy([es]));
    newPeers.identities.addAll(currentIdentity.peers.identities);
    currentIdentity.peers = newPeers;

    currentIdentities[appStateBloc.current.selectedIdentity] = currentIdentity;
    await set(currentIdentities);
  }

  /// Remove the given entity from the currently selected identity's subscriptions
  unsubscribe(Entity entity) async {
    // TODO: Remove the entity summary from the identity
    // TODO: Check if other identities are also subscribed
    // TODO: Remove the full entity if not used elsewhere
    // TODO: Remove the entity feeds if not used elsewhere
  }
}
