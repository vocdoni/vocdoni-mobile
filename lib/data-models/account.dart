import 'dart:convert';
import 'dart:math';

import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:flutter/foundation.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/lib/errors.dart';
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

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.load(List<AccountModel>());

    try {
      this.setToLoading();
      final identitiesList = globalIdentitiesPersistence.get();
      final identityModelList = identitiesList
          .where((identity) => identity.meta[META_ACCOUNT_ID] is String)
          .map((identity) {
            final result = AccountModel.fromIdentity(identity);

            // Decode extra fields
            final failedAttempts = int.tryParse(
                    identity.meta[META_ACCOUNT_FAILED_ATTEMPTS] ?? "0") ??
                0;
            final authThresholdDate = DateTime.tryParse(
                    identity.meta[META_ACCOUNT_AUTH_THRESHOLD_DATE]) ??
                DateTime.now();
            result.failedAuthAttempts.load(failedAttempts);
            result.authThresholdDate.load(authThresholdDate);

            return result;
          })
          .cast<AccountModel>()
          .toList();
      this.setValue(identityModelList);
    } catch (err) {
      if (!kReleaseMode) print(err);
      this.setError("Cannot read the boot nodes list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the given collection of all objects to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.load(List<AccountModel>());

    try {
      final identitiesList = this
          .value
          .where((accountModel) => accountModel.identity.hasValue)
          .map((accountModel) {
            final identity = accountModel.identity.value;

            // Failed attempts
            if (accountModel.failedAuthAttempts.hasValue)
              identity.meta[META_ACCOUNT_FAILED_ATTEMPTS] =
                  accountModel.failedAuthAttempts.value.toString();
            else
              identity.meta[META_ACCOUNT_FAILED_ATTEMPTS] = "0";

            // When will the user be able to try again
            if (accountModel.authThresholdDate.hasValue)
              identity.meta[META_ACCOUNT_AUTH_THRESHOLD_DATE] =
                  accountModel.authThresholdDate.value.toIso8601String();
            else
              identity.meta[META_ACCOUNT_AUTH_THRESHOLD_DATE] =
                  DateTime.now().toIso8601String();

            return identity;
          })
          .cast<Identity>()
          .toList();
      await globalIdentitiesPersistence.writeAll(identitiesList);

      // Caschade the write request for the peer entities
      await globalEntityPool.writeToStorage();
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw PersistError("Cannot store the current state");
    }
  }

  // CUSTOM METHODS

  /// Adds the new account to the collection and adds the peer entities to the entities poll
  /// Persists the new account pool.
  addAccount(AccountModel newAccount) async {
    if (!this.hasValue)
      throw Exception("The pool has no accounts loaded yet");
    else if (!newAccount.identity.hasValue ||
        newAccount.identity.value.keys.length == 0)
      throw Exception("The account needs to have an identity set");

    // Prevent duplicates
    final duplicate = this.value.any((account) =>
        account.identity.value.keys.length > 0 &&
        account.identity.value.keys[0].publicKey ==
            newAccount.identity.value.keys[0].publicKey);

    if (duplicate) {
      if (!kReleaseMode)
        print("WARNING: Attempting to add a duplicate identity. Skipping.");
      return;
    }

    // Add identity to global identities persistence
    final newAccountList = this.value;
    newAccountList.add(newAccount);
    this.setValue(newAccountList);

    await this.writeToStorage();
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

  final StateModel<String> timestampUsedToSign = StateModel<String>()
      .withFreshness(21600); // The timestamp string used to sign
  final StateModel<String> signedTimestamp = StateModel<String>()
      .withFreshness(21600); // The signature. Used for action visibility checks

  // CONSTRUCTORS

  /// Create a model with the given identity and the peer entities found on the Entity Pool
  AccountModel.fromIdentity(Identity idt) {
    this.identity.load(idt);

    if (globalEntityPool.hasValue) {
      final entityList = this
          .identity
          .value
          .peers
          .entities
          .map((EntityReference entitySummary) =>
              EntityModel.getFromPool(entitySummary))
          .toList();

      this.entities.load(entityList);
    }
  }

  /// Trigger a refresh of the related entities metadata.
  /// Also recompute the signed timestamp so that entity actions can be checked
  /// for visibility.
  @override
  Future<void> refresh([String patternEncryptionKey]) async {
    if (this.entities.hasValue) {
      await Future.wait(this.entities.value.map((e) => e.refresh()));
    }
    if (patternEncryptionKey is String)
      await refreshSignedTimestamp(patternEncryptionKey);
  }

  Future<void> refreshSignedTimestamp(String patternEncryptionKey) async {
    final encryptedPrivateKey = identity.value.keys[0].encryptedPrivateKey;
    final privateKey =
        await decryptString(encryptedPrivateKey, patternEncryptionKey);

    final ts = DateTime.now().millisecondsSinceEpoch.toString();

    final payload = jsonEncode({"timestamp": ts});
    final signature = await signString(payload, privateKey);
    this.signedTimestamp.setValue(signature);
    this.timestampUsedToSign.setValue(ts);
  }

  // PUBLIC METHODS

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

  bool isSubscribed(EntityReference entityReference) {
    if (!this.identity.hasValue) return false;
    return this.identity.value.peers.entities.any((existingEntitiy) {
      return entityReference.entityId == existingEntitiy.entityId;
    });
  }

  /// Register the given organization as a subscribtion of the currently selected identity.
  /// Persists the updated pool.
  subscribe(EntityModel entityReference) async {
    if (entityReference.reference == null)
      throw Exception("The entity has no reference");
    else if (isSubscribed(entityReference.reference)) return;

    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(identity.value.peers.entities); // clone existing
    peers.identities.addAll(identity.value.peers.identities); // clone existing

    peers.entities.add(entityReference.reference); // new entity

    final updatedIdentity = this.identity.value;
    updatedIdentity.peers = peers;
    this.identity.setValue(updatedIdentity);

    final newPeerEntities = this.entities.value;
    newPeerEntities.add(entityReference);
    this.entities.setValue(newPeerEntities);

    await globalAccountPool.writeToStorage();
  }

  /// Remove the given entity from the currently selected identity's subscriptions
  unsubscribe(EntityReference entityReference) async {
    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(this.identity.value.peers.entities);
    peers.entities.removeWhere((existingEntity) =>
        existingEntity.entityId == entityReference.entityId);
    peers.identities.addAll(this.identity.value.peers.identities);

    final updatedIdentity = this.identity.value;
    updatedIdentity.peers = peers;
    this.identity.setValue(updatedIdentity);

    // Get ourselves
    final currentAccount = globalAppState.getSelectedAccount();
    if (!(currentAccount is AccountModel))
      throw Exception("No account is currently selected");
    else if (!currentAccount.identity.hasValue ||
        !currentAccount.entities.hasValue)
      throw Exception("The current identity is not properly initialized");

    // Check if other identities are also subscribed
    bool subscribedFromOtherAccounts = false;
    for (final existingAccount in globalAccountPool.value) {
      if (!existingAccount.identity.hasValue ||
          !existingAccount.entities.hasValue)
        continue;
      else if (existingAccount.identity.value.keys.length == 0)
        continue;
      // skip ourselves
      else if (existingAccount.identity.value.keys[0].publicKey ==
          currentAccount.identity.value.keys[0].publicKey) continue;

      if (isSubscribed(entityReference)) {
        subscribedFromOtherAccounts = true;
        break;
      }
    }

    // Clean the entity otherwise
    if (!subscribedFromOtherAccounts) {
      await globalEntityPool.remove(entityReference);
    }

    await globalAccountPool.writeToStorage();
  }

  // addEntityPeerToAccount(EntityReference entitySummary, Identity account) {
  //   Identity_Peers peers = Identity_Peers();
  //   peers.entities.addAll(account.peers.entities);
  //   peers.entities.add(entitySummary);
  //   peers.identities.addAll(account.peers.identities);
  //   account.peers = peers;
  // }

  // removeEntityPeerFromAccount(String entityIdToRemove, Identity account) {
  //   Identity_Peers peers = Identity_Peers();
  //   peers.entities.addAll(account.peers.entities);
  //   peers.entities.removeWhere(
  //       (existingEntity) => existingEntity.entityId == entityIdToRemove);
  //   peers.identities.addAll(account.peers.identities);
  //   account.peers = peers;
  // }

  // STATIC METHODS

  /// Returns a Model with the identity restored from the given mnemonic and an empty list of entities.
  /// NOTE: The returned model is not added to the global pool.
  static Future<AccountModel> restoredFromMnemonic(
      String alias, String mnemonic, String patternEncryptionKey) async {
    if (!(alias is String) || alias.length < 1)
      throw Exception("Invalid alias");
    else if (!(mnemonic is String) || mnemonic.length < 2)
      throw Exception("Invalid patternEncryptionKey");
    else if (!(patternEncryptionKey is String) ||
        patternEncryptionKey.length < 2)
      throw Exception("Invalid patternEncryptionKey");

    final currentIdentities = globalIdentitiesPersistence.get();
    alias = alias.trim();
    final reducedAlias = alias.toLowerCase().trim();
    if (currentIdentities
            .where((item) => item.alias.toLowerCase().trim() == reducedAlias)
            .length >
        0) {
      throw Exception("An account with this name already exists");
    }

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

    AccountModel result = AccountModel.fromIdentity(newIdentity);
    await result.refreshSignedTimestamp(patternEncryptionKey);

    return result;
  }

  /// Populates the object with a new identity and an empty list of organizations.
  /// NOTE: The returned model is not added to the global pool.
  static Future<AccountModel> makeNew(
      String alias, String patternEncryptionKey) async {
    if (!(alias is String) || alias.length < 1)
      throw Exception("Invalid alias");
    else if (!(patternEncryptionKey is String) ||
        patternEncryptionKey.length < 2)
      throw Exception("Invalid patternEncryptionKey");

    final currentIdentities = globalIdentitiesPersistence.get();
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

    AccountModel result = AccountModel.fromIdentity(newIdentity);
    await result.refreshSignedTimestamp(patternEncryptionKey);

    return result;
  }
}
