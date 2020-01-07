import 'dart:math';

import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/state-value.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// AccountPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
class AccountPoolModel extends StateModel<List<AccountModel>> {
  // OVERRIDES

  @override
  readFromStorage() {
    // TODO: implement readFromStorage
    return null;
  }

  @override
  writeToStorage() {
    // TODO: Store failedAuthAttempts and authThresholdDate
    print("TO DO: Store failedAuthAttempts and authThresholdDate");

    // TODO: implement writeToStorage
    return null;
  }

  // CUSTOM METHODS

  addAccount(AccountModel newAccount) {
    // TODO: prevent duplicates

    // TODO: ADD identity to global identities persistence
    // TODO: ADD entities to global entities persistence
    // TODO: ADD account to array

    // TODO: PERSIST

    notifyListeners();
  }
}

/// AccountModel encapsulates the relevant information of a Vocdoni account.
/// This includes the personal identity information and the entities subscribed to.
/// Persistence is handled by the related identity and the relevant EntityModels.
///
/// IMPORTANT: All **updates** on the state must call `notifyListeners()`
///
class AccountModel extends StateModel<AccountState> {
  // CONSTRUCTORS

  AccountModel.fromIdentity(Identity idt) {
    this.value.identity = idt;

    this.value.entities = this
        .identity
        .peers
        .entities
        .map((EntityReference entitySummary) => EntityModel(entitySummary))
        .toList();
  }

  AccountModel.fromExisting(String alias, String mnemonic) {
    // TODO: implement

    notifyListeners();
  }

  // OVERRIDES
  @override
  readFromStorage() async {
    // TODO:
  }

  @override
  writeToStorage() async {
    final allIdentities = await globalIdentitiesPersistence.readAll();

    // TODO: find our identity on the list
    // TODO: UPDATE with the current identity value

    await globalIdentitiesPersistence.writeAll(allIdentities);

    // TODO: Same with entities
  }

  // CUSTOM METHODS

  /// Populates the object with a new identity and an empty list of organizations
  makeNew(String alias, String patternEncryptionKey) async {
    if (!(alias is String) || alias.length < 2)
      throw Exception("Invalid alias");
    else if (!(patternEncryptionKey is String) ||
        patternEncryptionKey.length < 2)
      throw Exception("Invalid patternEncryptionKey");

    final currentIdentities = await globalIdentitiesPersistence.readAll();
    alias = alias.trim();
    final reducedAlias = alias.toLowerCase().trim();
    if (currentIdentities
            .where((item) => item.alias.toLowerCase().trim() == reducedAlias)
            .length >
        0) {
      throw Exception("An account with this name already exists");
    }

    final mnemonic = await generateMnemonic(size: 192);
    final privateKey = await mnemonicToPrivateKey(mnemonic);
    final publicKey = await mnemonicToPublicKey(mnemonic);
    final address = await mnemonicToAddress(mnemonic);
    final encryptedMenmonic =
        await encryptString(mnemonic, patternEncryptionKey);
    final encryptedPrivateKey =
        await encryptString(privateKey, patternEncryptionKey);

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
    this.value.identity = newIdentity;
  }

  /// Trigger a refresh of the related entities metadata
  @override
  Future<void> refresh() {
    return Future.wait(this.value.entities.map((e) => e.refresh()));
  }

  Future<void> trackSuccessfulAuth() {
    // TODO: Implement
  }

  Future<void> trackFailedAuth() {
    // TODO: Implement
  }

  bool isSubscribed(EntityReference _entitySummary) {
    return this.value.identity.peers.entities.any((existingEntitiy) {
      return _entitySummary.entityId == existingEntitiy.entityId;
    });
  }

  /// Register the given organization as a subscribtion of the currently selected identity
  subscribe(EntityModel entity) async {
    if (isSubscribed(entity.entityReference)) return;

    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(identity.peers.entities); // clone
    peers.identities.addAll(identity.peers.identities); // clone

    peers.entities.add(entity.entityReference); // new entity
    identity.peers = peers;

    this.value.entities.add(entity);

    notifyListeners();
    await writeToStorage();
  }

  /// Remove the given entity from the currently selected identity's subscriptions
  unsubscribe(EntityReference _entitySummary) async {
    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(this.value.identity.peers.entities);
    peers.entities.removeWhere(
        (existingEntity) => existingEntity.entityId == _entitySummary.entityId);
    peers.identities.addAll(this.value.identity.peers.identities);
    this.value.identity.peers = peers;

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

    // await identitiesBloc.unsubscribeEntityFromAccount(
    //     _entitySummary, this.value.identity.identity);
    // int index = entities.indexWhere(
    //     (ent) => _entitySummary.entityId == ent.entityReference.entityId);
    // if (index != -1) entities.removeAt(index);
  }

  Future trackAuthAttemp(bool successful) async {
    final newState = value;
    var newThreshold = DateTime.now();
    if (successful) {
      newState.failedAuthAttempts = 0;
    } else {
      newState.failedAuthAttempts++;
      final seconds = pow(2, newState.failedAuthAttempts);
      newThreshold.add(Duration(seconds: seconds));
    }
    newState.authThresholdDate = newThreshold;
    notifyListeners();
    await writeToStorage();
  }
}

// Use this class as a data container only. Any logic that updates the state
// should be defined above in the model class
class AccountState {
  final Identity identity;
  final StateValue<List<EntityModel>> entities;

  int failedAuthAttempts = 0;
  DateTime authThresholdDate = DateTime.now();
  // final List<String> languages = ["default"];

  AccountState(this.identity, this.entities, this.failedAuthAttempts,
      this.authThresholdDate);
}
