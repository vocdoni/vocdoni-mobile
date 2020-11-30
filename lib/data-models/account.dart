import 'dart:math' hide log;
import 'package:dvote/dvote.dart';
import 'package:dvote/dvote.dart' as dvote;
import 'package:dvote_crypto/dvote_crypto.dart';
import "dart:developer";
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/model-base.dart';
import 'package:eventual/eventual.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/globals.dart';

/// This class should be used exclusively as a global singleton.
/// AccountPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// This class provides an abstraction layer to encapsulate everything related to a personal account.
/// This is, the underlying identity and all the relevant metadata.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateContainer or EventualNotifier.
///
class AccountPoolModel extends EventualNotifier<List<AccountModel>>
    implements ModelPersistable {
  AccountPoolModel() {
    this.setDefaultValue(List<AccountModel>());
  }

  // OVERRIDES

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.setValue(List<AccountModel>());

    try {
      this.setToLoading();
      final identitiesList = Globals.identitiesPersistence.get();
      final accountModelList = identitiesList
          .where((identity) => identity.meta[META_ACCOUNT_ID] is String)
          .map((identity) {
            final result = AccountModel.fromIdentity(identity);

            final entities = identity.peers.entities
                .map((entityRef) => Globals.entityPool.value.firstWhere(
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
            result.failedAuthAttempts.setValue(failedAttempts);
            result.authThresholdDate.setValue(authThresholdDate);

            return result;
          })
          .cast<AccountModel>()
          .toList();
      this.setValue(accountModelList);
    } catch (err) {
      log(err);
      this.setError("Cannot read the account list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the given collection of all objects to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.setValue(List<AccountModel>());

    try {
      final identitiesList = this
          .value
          .where((accountModel) =>
              accountModel.identity.hasValue &&
              accountModel.identity.value.keys.length > 0)
          .map((accountModel) {
            final identity = accountModel.identity.value;

            identity.meta[META_ACCOUNT_ID] =
                accountModel.identity.value.keys[0].rootAddress;

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
      await Globals.identitiesPersistence.writeAll(identitiesList);

      // Cascade the write request for the peer entities
      await Globals.entityPool.writeToStorage();
    } catch (err) {
      log(err);
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

    final currentIdentities = Globals.identitiesPersistence.get();
    final alias = newAccount.identity.value.alias.trim();
    final reducedAlias = alias.toLowerCase().trim();
    if (currentIdentities
            .where((item) => item.alias.toLowerCase().trim() == reducedAlias)
            .length >
        0) {
      throw Exception("main.anAccountWithThisNameAlreadyExists");
    }

    // Prevent duplicates
    final duplicate = this.value.any((account) =>
        account.identity.value.keys.length > 0 &&
        account.identity.value.keys[0].rootPublicKey ==
            newAccount.identity.value.keys[0].rootPublicKey);

    if (duplicate) {
      log("WARNING: Attempting to add a duplicate identity. Skipping.");
      return;
    }

    // Add identity to global identities and persist
    final newAccountList = this.value;
    newAccountList.add(newAccount);
    this.setValue(newAccountList);

    await this.writeToStorage();
  }

  /// Removes the current account from the account pool
  /// Persists the new account pool.
  removeCurrentAccount() async {
    log("[Account] Removing current account");
    if (!this.hasValue)
      throw Exception("The pool has no accounts loaded yet");
    else if (!Globals.appState.selectedAccount.hasValue)
      throw Exception("The current account is not set");
    else if (Globals.appState.selectedAccount.value > this.value.length)
      throw Exception("The current account does not exist");

    // Remove identity from global identities and persist
    final newAccountList = this.value;
    newAccountList.removeAt(Globals.appState.selectedAccount.value);
    this.setValue(newAccountList);

    await this.writeToStorage();
  }
}

/// AccountModel encapsulates the relevant information of a Vocdoni account.
/// This includes the personal identity information and the entities subscribed to.
/// Persistence is handled by the related identity and the relevant EntityModels.
///
class AccountModel implements ModelRefreshable, ModelCleanable {
  final identity = EventualNotifier<Identity>();

  /// generated from `identity.peers.entities`
  final entities = EventualNotifier<List<EntityModel>>();

  final failedAuthAttempts = EventualNotifier<int>(0);
  final authThresholdDate = EventualNotifier<DateTime>(DateTime.now());

  /// A map containing the user's public key (hex) for each entity
  final _derivedPublicKeysPerEntity = Map<String, String>();

  // CONSTRUCTORS

  /// Create a model with the given identity and the peer entities found on the Entity Pool
  AccountModel.fromIdentity(Identity idt) {
    this.identity.setDefaultValue(idt);

    if (!Globals.entityPool.hasValue) return;

    final entityList = this
        .identity
        .value
        .peers
        .entities
        .map((EntityReference entitySummary) =>
            EntityModel.getFromPool(entitySummary))
        .where((e) => e != null)
        .cast<EntityModel>()
        .toList();

    this.entities.setDefaultValue(entityList);
  }

  /// Trigger a refresh of the related entities metadata.
  /// Also recompute the signed timestamps so that entity actions can be checked
  /// for visibility.
  @override
  Future<void> refresh(
      {bool force = false, String patternEncryptionKey}) async {
    if (!this.entities.hasValue) return;

    if (patternEncryptionKey is String) {
      // Refresh with private key available

      final currentAccount = Globals.appState.currentAccount;
      if (currentAccount is! AccountModel) return;

      final mnemonic = Symmetric.decryptString(
          currentAccount.identity.value.keys[0].encryptedMnemonic,
          patternEncryptionKey);
      if (mnemonic == null) return;

      for (final entity in this.entities.value) {
        final wallet = EthereumWallet.fromMnemonic(mnemonic,
            entityAddressHash: entity.reference.entityId);

        // Store the public key within the map for future use
        if (!hasPublicKeyForEntity(entity.reference.entityId)) {
          setPublicKeyForEntity(await wallet.publicKeyAsync(uncompressed: true),
              entity.reference.entityId);
        }

        await entity.refresh(
            force: force, derivedPrivateKey: await wallet.privateKeyAsync);
      }
    } else {
      // Shallow refresh, using what is already available (no private/public key available here)

      for (final entity in this.entities.value) {
        await entity.refresh(force: force);
      }
    }
  }

  // PUBLIC METHODS

  Future<void> trackSuccessfulAuth() {
    var newThreshold = DateTime.now();
    this.failedAuthAttempts.setValue(0);
    this.authThresholdDate.setValue(newThreshold);
    return Future.delayed(Duration(milliseconds: 50))
        .then((_) => Globals.accountPool.writeToStorage());
  }

  Future<void> trackFailedAuth() {
    this.failedAuthAttempts.setValue(this.failedAuthAttempts.value + 1);
    final seconds = pow(2, this.failedAuthAttempts.value);
    var newThreshold = DateTime.now().add(Duration(seconds: seconds));
    this.authThresholdDate.setValue(newThreshold);
    return Globals.accountPool.writeToStorage();
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
    if (!Globals.entityPool.value.any(
        (item) => item.reference.entityId == entityModel.reference.entityId)) {
      final newEntityPool = Globals.entityPool.value;
      newEntityPool.add(entityModel);
      Globals.entityPool.setValue(newEntityPool);
    }

    await Globals.accountPool.writeToStorage();
  }

  /// Remove the given entity from the currently selected account's identity subscriptions
  Future<void> unsubscribe(EntityReference entityReference) async {
    if (!this.identity.hasValue || !this.entities.hasValue)
      throw Exception("The current identity is not properly initialized");

    final entityModel = Globals.entityPool.value.firstWhere(
        (item) => item.reference.entityId == entityReference.entityId,
        orElse: () => null);
    if (entityModel == null) throw Exception("Entity not found");

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

    // Unregister push notifications for the current account
    await entityModel.disableNotifications();

    // Check if other identities are also following the entity
    final currentAddress = this.identity.value.keys[0].rootAddress;
    bool subscribedFromOtherAccounts = false;
    for (final existingAccount in Globals.accountPool.value) {
      if (!existingAccount.identity.hasValue ||
          !existingAccount.entities.hasValue ||
          existingAccount.identity.value.keys.length == 0)
        continue;
      // skip ourselves
      else if (existingAccount.identity.value.keys[0].rootAddress ==
          currentAddress)
        continue;
      else if (!existingAccount.isSubscribed(entityReference)) continue;

      subscribedFromOtherAccounts = true;
      break;
    }

    // Wipe the entity
    if (!subscribedFromOtherAccounts) {
      await Globals.entityPool.remove(entityReference);
    }

    await Globals.accountPool.writeToStorage();
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

  String getPublicKeyForEntity(String entityId) {
    return _derivedPublicKeysPerEntity[entityId];
  }

  bool hasPublicKeyForEntity(String entityId) {
    return _derivedPublicKeysPerEntity.containsKey(entityId);
  }

  void setPublicKeyForEntity(String derivedPublicKey, String entityId) {
    _derivedPublicKeysPerEntity[entityId] = derivedPublicKey;
  }

  /// Cleans the ephemeral state of the account's subscribed entities
  @override
  void cleanEphemeral() {
    this.entities.value.forEach((entity) => entity.cleanEphemeral());
  }

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

    final wallet = EthereumWallet.fromMnemonic(mnemonic);

    final rootPrivateKey = await wallet.privateKeyAsync;
    final rootPublicKey = await wallet.publicKeyAsync(uncompressed: true);
    final rootAddress = await wallet.addressAsync;
    final encryptedMenmonic =
        await Symmetric.encryptStringAsync(mnemonic, patternEncryptionKey);
    final encryptedRootPrivateKey = await Symmetric.encryptStringAsync(
        rootPrivateKey, patternEncryptionKey);

    Identity newIdentity = Identity();
    newIdentity.alias = alias;
    newIdentity.identityId = rootPublicKey;
    newIdentity.type = Identity_Type.ECDSA;

    dvote.Key k = dvote.Key();
    k.type = Key_Type.SECP256K1;
    k.encryptedMnemonic = encryptedMenmonic;
    k.encryptedRootPrivateKey = encryptedRootPrivateKey;
    k.rootPublicKey = rootPublicKey;
    k.rootAddress = rootAddress;

    newIdentity.keys.add(k);

    return AccountModel.fromIdentity(newIdentity);
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

    final wallet = await EthereumWallet.randomAsync(size: 192);

    final mnemonic = wallet.mnemonic;
    final rootPrivateKey = await wallet.privateKeyAsync;
    final rootPublicKey = await wallet.publicKeyAsync(uncompressed: true);
    final rootAddress = await wallet.addressAsync;
    final encryptedMenmonic =
        await Symmetric.encryptStringAsync(mnemonic, patternEncryptionKey);
    final encryptedRootPrivateKey = await Symmetric.encryptStringAsync(
        rootPrivateKey, patternEncryptionKey);

    Identity newIdentity = Identity();
    newIdentity.alias = alias;
    newIdentity.identityId = rootPublicKey;
    newIdentity.type = Identity_Type.ECDSA;

    dvote.Key k = dvote.Key();
    k.type = Key_Type.SECP256K1;
    k.encryptedMnemonic = encryptedMenmonic;
    k.encryptedRootPrivateKey = encryptedRootPrivateKey;
    k.rootPublicKey = rootPublicKey;
    k.rootAddress = rootAddress;

    newIdentity.keys.add(k);
    newIdentity.meta[META_ACCOUNT_ID] = rootAddress;

    return AccountModel.fromIdentity(newIdentity);
  }
}
