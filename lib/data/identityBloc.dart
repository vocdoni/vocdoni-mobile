import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/data/genericBloc.dart';
import 'package:vocdoni/util/api.dart';
import "dart:async";

import 'package:vocdoni/util/singletons.dart';

class IdentityBloc extends GenericBloc<List<Identity>> {
  final String _storageFile = IDENTITIES_STORE_FILE;

  IdentityBloc() {
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
      throw BlocRestoreError(
          "There was an error while accessing the local data");
    }

    try {
      final bytes = await fd.readAsBytes();
      store = IdentitiesStore.fromBuffer(bytes);
      state.add(store.items);
    } catch (err) {
      print(err);
      throw BlocRestoreError(
          "There was an error while processing the local data");
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
      throw BlocPersistError("There was an error while storing the changes");
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
      throw Exception("Invalid alias");
    else if (!(encryptionKey is String) || encryptionKey.length < 2)
      throw Exception("Invalid encryptionKey");

    alias = alias.trim();
    if (super.value.where((item) => item.alias == alias).length > 0) {
      throw Exception("The account already exists");
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
    //TODO Either the encryptedMnemonic or the encryptedPrivateKey should exists. Single source of truth
    k.encryptedMnemonic = encryptedMenmonic;
    k.encryptedPrivateKey = encryptedPrivateKey;
    k.publicKey = publicKey;
    k.address = address;

    //TOOD check why
    newIdentity.keys.add(k);

    // Add to existing, notify and store
    super.value.add(newIdentity);
    set(super.value);
  }

  Identity getCurrentIdentity() {
    if (super.state.value.length <= appStateBloc.value?.selectedIdentity)
      throw Exception("Invalid selectedIdentity: out of bounds");

    final identity = identitiesBloc.value[appStateBloc.value.selectedIdentity];
    if (!(identity is Identity))
      throw Exception("The current account is invalid");
    return identity;
  }

  setCurrentAccount(Identity account) async {
    final identitiesValue = identitiesBloc.value;
    identitiesValue[appStateBloc.value.selectedIdentity] = account;
    await set(identitiesValue);
  }

  addEntityPeerToAccount(EntityReference entitySummary, Identity account) {
    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(account.peers.entities);
    peers.entities.add(entitySummary);
    peers.identities.addAll(account.peers.identities);
    account.peers = peers;
  }

  removeEntityPeerFromAccount(String entityIdToRemove, Identity account) {
    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(account.peers.entities);
    peers.entities.removeWhere(
        (existingEntity) => existingEntity.entityId == entityIdToRemove);
    peers.identities.addAll(account.peers.identities);
    account.peers = peers;
  }

  bool isSubscribed(Identity account, EntityReference entitySummary) {
    return account.peers.entities.any((existingEntitiy) {
      return entitySummary.entityId == existingEntitiy.entityId;
    });
  }

  /// Register the given organization as a subscribtion of the currently selected identity
  subscribeEntityToAccount(
      EntityReference entityReference, Identity account) async {
    // Add the entity to the global registry if it does not exist
    if (isSubscribed(account, entityReference))
      throw Exception("You are already subscribed to this entity");

    //EntityReference entitySummary = makeEntityReferenceFromEntity(entityMetadata);
    addEntityPeerToAccount(entityReference, account);
    setCurrentAccount(account);
  }

  /// Remove the given entity from the currently selected identity's subscriptions
  unsubscribeEntityFromAccount(
      EntityReference entitySummary, Identity account) async {
    // TODO: Remove the entity summary from the identity
    removeEntityPeerFromAccount(entitySummary.entityId, account);

    // TODO: Check if other identities are also subscribed
    bool subcribedInOtherAccounts = false;
    for (final existingAccount in identitiesBloc.value) {
      if (isSubscribed(existingAccount, entitySummary)) {
        subcribedInOtherAccounts = true;
        break;
      }
    }

    // TODO: Remove the full entity if not used elsewhere
    // TODO: Remove the entity feeds if not used elsewhere
    if (!subcribedInOtherAccounts) {
      await entitiesBloc.remove(entitySummary.entityId);
    }
  }
}
