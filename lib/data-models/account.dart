import 'dart:convert';
import 'dart:math';

import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/state-base.dart';
import 'package:vocdoni/lib/state-notifier.dart';
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
/// Updates on the children models will be notified by the objects themselves if using StateContainer or StateNotifier.
///
class AccountPoolModel extends StateNotifier<List<AccountModel>>
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
      final accountModelList = identitiesList
          .where((identity) => identity.meta[META_ACCOUNT_ID] is String)
          .map((identity) {
            final result = AccountModel.fromIdentity(identity);

            final entities = identity.peers.entities
                .map((entityRef) => globalEntityPool.value.firstWhere(
                    (entity) => entity.reference.entityId == entityRef.entityId,
                    orElse: () => null))
                .where((item) => item != null)
                .cast<EntityModel>()
                .toList();
            result.entities.setValue(entities);

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
      this.setValue(accountModelList);
    } catch (err) {
      devPrint(err);
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
          .where((accountModel) =>
              accountModel.identity.hasValue &&
              accountModel.identity.value.keys.length > 0)
          .map((accountModel) {
            final identity = accountModel.identity.value;

            identity.meta[META_ACCOUNT_ID] =
                accountModel.identity.value.keys[0].address;

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

      // Cascade the write request for the peer entities
      await globalEntityPool.writeToStorage();
    } catch (err) {
      devPrint(err);
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

    final currentIdentities = globalIdentitiesPersistence.get();
    final alias = newAccount.identity.value.alias.trim();
    final reducedAlias = alias.toLowerCase().trim();
    if (currentIdentities
            .where((item) => item.alias.toLowerCase().trim() == reducedAlias)
            .length >
        0) {
      throw Exception("An account with this name already exists");
    }

    // Prevent duplicates
    final duplicate = this.value.any((account) =>
        account.identity.value.keys.length > 0 &&
        account.identity.value.keys[0].publicKey ==
            newAccount.identity.value.keys[0].publicKey);

    if (duplicate) {
      devPrint("WARNING: Attempting to add a duplicate identity. Skipping.");
      return;
    }

    // Add identity to global identities and persist
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
  final StateNotifier<Identity> identity = StateNotifier<Identity>();
  final StateNotifier<List<EntityModel>> entities = StateNotifier<
      List<EntityModel>>(); // generated from `identity.peers.entities`

  final StateNotifier<int> failedAuthAttempts = StateNotifier<int>(0);
  final StateNotifier<DateTime> authThresholdDate =
      StateNotifier<DateTime>(DateTime.now());

  /// The original json string with the timestamp, used to make the signature
  final StateNotifier<String> timestampSigned =
      StateNotifier<String>().withFreshness(21600);

  /// The signature of `timestampSigned`. Used for action visibility checks
  final StateNotifier<String> timestampSignature =
      StateNotifier<String>().withFreshness(21600);

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
          .cast<EntityModel>()
          .toList();

      this.entities.load(entityList);
    }
  }

  /// Trigger a refresh of the related entities metadata.
  /// Also recompute the signed timestamp so that entity actions can be checked
  /// for visibility.
  @override
  Future<void> refresh(
      [bool force = false, String patternEncryptionKey]) async {
    if (this.entities.hasValue) {
      await Future.wait(this.entities.value.map((e) => e.refresh(force)));
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
    this.timestampSignature.setValue(signature);
    this.timestampSigned.setValue(ts);
  }

  // PUBLIC METHODS

  Future<void> trackSuccessfulAuth() {
    var newThreshold = DateTime.now();
    this.failedAuthAttempts.setValue(0);
    this.authThresholdDate.setValue(newThreshold);
    return Future.delayed(Duration(milliseconds: 50))
        .then((_) => globalAccountPool.writeToStorage());
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

  /// Register the given organization as a subscribtion of the currently selected account's identity.
  /// Persists the updated pool.
  Future<void> subscribe(EntityModel entityModel) async {
    if (entityModel.reference == null)
      throw Exception("The entity has no reference");

    if (!isSubscribed(entityModel.reference)) {
      Identity_Peers peers = Identity_Peers();
      peers.entities.addAll(identity.value.peers.entities); // clone existing
      peers.identities
          .addAll(identity.value.peers.identities); // clone existing

      peers.entities.add(entityModel.reference); // new entity

      final updatedIdentity = this.identity.value;
      updatedIdentity.peers = peers;
      this.identity.setValue(updatedIdentity);

      final newPeerEntities = this.entities.value;
      newPeerEntities.add(entityModel);
      this.entities.setValue(newPeerEntities);
    }

    // Add also the new model to the entities pool
    if (!globalEntityPool.value.any(
        (item) => item.reference.entityId == entityModel.reference.entityId)) {
      final newEntityPool = globalEntityPool.value;
      newEntityPool.add(entityModel);
      globalEntityPool.setValue(newEntityPool);
    }

    await globalAccountPool.writeToStorage();
  }

  /// Remove the given entity from the currently selected account's identity subscriptions
  Future<void> unsubscribe(EntityReference entityReference) async {
    if (!this.identity.hasValue || !this.entities.hasValue)
      throw Exception("The current identity is not properly initialized");

    // Update identity subscriptions
    Identity_Peers peers = Identity_Peers();
    peers.entities.addAll(this.identity.value.peers.entities);
    peers.entities.removeWhere((existingEntity) =>
        existingEntity.entityId == entityReference.entityId);
    peers.identities.addAll(this.identity.value.peers.identities);

    final updatedIdentity = this.identity.value;
    updatedIdentity.peers = peers;
    this.identity.setValue(updatedIdentity);

    // Update in-memory models
    final newEntityList = this
        .entities
        .value
        .where((item) => item.reference.entityId != entityReference.entityId)
        .cast<EntityModel>()
        .toList();
    this.entities.setValue(newEntityList);

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
          this.identity.value.keys[0].publicKey) continue;

      if (existingAccount.isSubscribed(entityReference)) {
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
  static Future<AccountModel> fromMnemonic(
      String mnemonic, String alias, String patternEncryptionKey) async {
    if (!(mnemonic is String) || mnemonic.length < 2)
      throw Exception("Invalid patternEncryptionKey");
    else if (!(alias is String) || alias.length < 1)
      throw Exception("Invalid alias");
    else if (!(patternEncryptionKey is String) ||
        patternEncryptionKey.length < 2)
      throw Exception("Invalid patternEncryptionKey");

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
    newIdentity.meta[META_ACCOUNT_ID] = address;

    AccountModel result = AccountModel.fromIdentity(newIdentity);
    await result.refreshSignedTimestamp(patternEncryptionKey);

    return result;
  }
}
