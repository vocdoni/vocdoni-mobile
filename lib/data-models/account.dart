import 'dart:math';

import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:vocdoni/lib/state-base.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// AccountPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// This class provides an abstraction layer to encapsulate everything related to a personal account.
/// This is, the underlying identity and all the relevant metadata.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateValue or StateModel.
///
class AccountPoolModel extends StateModel<List<AccountModel>>
    implements StatePersistable {
  AccountPoolModel() {
    this.setValue(List<AccountModel>());
  }

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
class AccountModel implements StateRefreshable {
  final StateModel<Identity> identity = StateModel<Identity>();
  final StateModel<List<EntityModel>> entities =
      StateModel<List<EntityModel>>();

  final StateModel<int> failedAuthAttempts = StateModel<int>(0);
  final StateModel<DateTime> authThresholdDate =
      StateModel<DateTime>(DateTime.now());
  // final List<String> languages = ["default"];

  // CONSTRUCTORS

  // AccountModel.fromIdentity(Identity idt) {
  //   final newValue = AccountState(idt, );
  //   this.value.identity = idt;

  //   this.value.entities = this
  //       .identity
  //       .peers
  //       .entities
  //       .map((EntityReference entitySummary) => EntityModel(entitySummary))
  //       .toList();
  // }

  // AccountModel.fromExisting(String alias, String mnemonic) {
  //   // TODO: implement

  //   notifyListeners();
  // }

  // // OVERRIDES
  // @override
  // readFromStorage() async {
  //   // TODO:
  // }

  // @override
  // writeToStorage() async {
  //   final allIdentities = await globalIdentitiesPersistence.readAll();

  //   // TODO: find our identity on the list
  //   // TODO: UPDATE with the current identity value

  //   await globalIdentitiesPersistence.writeAll(allIdentities);

  //   // TODO: Same with entities
  // }

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
    this.identity.setValue(newIdentity);
  }

  /// Trigger a refresh of the related entities metadata
  @override
  Future<void> refresh() {
    if (!this.entities.hasValue) return Future.value();
    return Future.wait(this.entities.value.map((e) => e.refresh()));
  }

  Future<void> trackSuccessfulAuth() {
    var newThreshold = DateTime.now();
    this.failedAuthAttempts.setValue(0);
    this.authThresholdDate.setValue(newThreshold);
    return globalAccountPool.writeToStorage();
  }

  Future<void> trackFailedAuth() {
    this.failedAuthAttempts.setValue(this.failedAuthAttempts.value + 1);
    final seconds = pow(2, this.failedAuthAttempts.value);
    var newThreshold = DateTime.now().add(Duration(seconds: seconds));
    this.authThresholdDate.setValue(newThreshold);
    return globalAccountPool.writeToStorage();
  }

  bool isSubscribed(EntityReference _entitySummary) {
    if (!this.identity.hasValue) return false;
    return this.identity.value.peers.entities.any((existingEntitiy) {
      return _entitySummary.entityId == existingEntitiy.entityId;
    });
  }

  /// Register the given organization as a subscribtion of the currently selected identity
  subscribe(EntityModel entity) async {
    if (!entity.hasValue)
      throw Exception("The entity model has no value");
    else if (isSubscribed(entity.value.reference)) return;

    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(identity.value.peers.entities); // clone
    peers.identities.addAll(identity.value.peers.identities); // clone

    peers.entities.add(entity.value.reference); // new entity
    identity.value.peers = peers;

    final newEntitiesList = this.entities.value;
    newEntitiesList.add(entity);
    this.entities.setValue(newEntitiesList);

    await globalAccountPool.writeToStorage();
  }

  /// Remove the given entity from the currently selected identity's subscriptions
  unsubscribe(EntityReference _entitySummary) async {
    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(this.identity.value.peers.entities);
    peers.entities.removeWhere(
        (existingEntity) => existingEntity.entityId == _entitySummary.entityId);
    peers.identities.addAll(this.identity.value.peers.identities);
    this.identity.value.peers = peers;

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
    //     _entitySummary, this.identity.identity);
    // int index = entities.indexWhere(
    //     (ent) => _entitySummary.entityId == ent.entityReference.entityId);
    // if (index != -1) entities.removeAt(index);
  }
}
