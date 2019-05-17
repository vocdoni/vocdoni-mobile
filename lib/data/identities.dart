import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "dart:convert";

import 'package:vocdoni/util/singletons.dart';

///
/// STORAGE STRUCTURE
/// - SharedPreferences > "accounts" > String List > address (String)
/// - SecureStorage > {account-address} > { mnemonic, publicKey, alias }
/// - SharedPreferences > "{account-address}-organizations" > String List > { name, ... }

final secStore = new FlutterSecureStorage();

class IdentitiesBloc {
  BehaviorSubject<List<Identity>> _state =
      BehaviorSubject<List<Identity>>.seeded(List<Identity>());

  Observable<List<Identity>> get stream => _state.stream;
  List<Identity> get current => _state.value;

  Future restore() async {
    return fetchState();
  }

  Future fetchState() async {
    // Read and construct the data structures (without the private data/mnemonic)

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
      if (prefs.containsKey("$addr-organizations")) {
        orgs = prefs.getStringList("$addr-organizations");
      }

      // Intentionally skip the mnemonic
      return Identity(
        publicKey: decoded["publicKey"],
        alias: decoded["alias"],
        mnemonic: null,
        address: addr,
        organizations: orgs
            .where((String org) => org != null)
            .map((String org) => Organization.fromJson(jsonDecode(org)))
            .toList(),
      );
    }));
    identities = identities.where((item) => item != null).toList();

    _state.add(identities);
  }

  // Operations

  /// Registers a new identity with an empty list of organizations
  create(
      {String mnemonic, String publicKey, String address, String alias}) async {
    if (!(mnemonic is String))
      throw ("Invalid mnemonic");
    else if (!(publicKey is String))
      throw ("Invalid publicKey");
    else if (!(address is String))
      throw ("Invalid address");
    else if (!(alias is String)) throw ("Invalid alias");

    // ADD THE ADDRESS IN THE ACCOUNT INDEX
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey("accounts")) {
      final currentAddrs = prefs.getStringList("accounts");
      if (currentAddrs.length > 0) {
        if (currentAddrs.indexWhere((addr) => addr == address) >= 0 ||
            (await secStore.read(key: address)) != null) {
          throw ("The account already exists");
        } else {
          currentAddrs.add(address);
          prefs.setStringList("accounts", currentAddrs);
        }
      } else {
        prefs.setStringList("accounts", [address]);
      }
    } else {
      prefs.setStringList("accounts", [address]);
    }

    // ADD A SERIALIZED WALLET FOR THE ADDRESS
    await secStore.write(
      key: address,
      value: json.encode(
          {"mnemonic": mnemonic, "publicKey": publicKey, "alias": alias}),
    );

    // ADD AN EMPTY LIST OF ORGANIZATIONS
    await prefs.setStringList("$address-organizations", []);

    // TODO: SET THE NEW IDENTITY AS THE ACTIVE

    // Refresh state
    fetchState();
  }

  /// Register the given organization as a subscribtion of the currently selected identity
  subscribe(Organization newOrganization) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_state.value.length <= appStateBloc.current?.selectedIdentity)
      throw ("Invalid selectedIdentity: out of bounds");

    final address =
        prefs.getStringList("accounts")[appStateBloc.current.selectedIdentity];
    if (!(address is String)) throw ("Invalid account address");

    List<String> accountOrganizations = [];
    if (prefs.containsKey("$address-organizations")) {
      accountOrganizations = prefs.getStringList("$address-organizations");
    }

    // TODO: CHECK NOT ALREADY SUBSCRIBED

    accountOrganizations.add(json.encode(newOrganization.toJson()));
    await prefs.setStringList("$address-organizations", accountOrganizations);
    // await prefs.setStringList("$address-organizations", []);

    appStateBloc.selectOrganization(accountOrganizations.length - 1);

    // Refresh state
    fetchState();
  }

  /// Remove the given organization from the currently selected identity's subscriptions
  unsubscribe(Organization org) {
    // TODO: PERSIST CHANGES
  }
}

class Identity {
  final String alias;
  final String mnemonic;
  final String publicKey;
  final String address;
  final List<Organization> organizations;

  Identity(
      {this.alias,
      this.publicKey,
      this.mnemonic,
      this.address,
      this.organizations});
}

class Organization {
  // Generic
  String resolverAddress;
  String entityId;
  String networkId;
  List<String> entryPoints; // TODO: REMOVE?

  // Metadata
  final List<String> languages;
  final String name;
  final Map<String, String> description; // language dependent
  final String metadataOrigin;
  final String votingProcessContractAddress;
  final List<String> activeProcessIds;
  final List<String> endedProcessIds;
  final Map<String, dynamic> newsFeed; // language dependent
  final String avatar;
  Map<String, dynamic> gatewayUpdate = {}; // unused
  List<String> gatewayBootNodes = []; // unused by now
  List<String> relays = []; // unused by now
  List actions = []; // unused by now

  Organization(
      {this.resolverAddress,
      this.entityId,
      this.networkId,
      this.entryPoints,
      this.languages,
      this.name,
      this.description,
      this.metadataOrigin,
      this.votingProcessContractAddress,
      this.activeProcessIds,
      this.endedProcessIds,
      this.newsFeed,
      this.avatar});

  Organization.fromJson(Map<String, dynamic> json)
      : // global
        resolverAddress = json['resolverAddress'] ?? "",
        entityId = json['entityId'] ?? "",
        networkId = json['networkId'] ?? "",
        entryPoints = (json['entryPoints'] ?? []).cast<String>().toList(),
        // meta
        languages = (json['languages'] ?? []).cast<String>().toList(),
        name = json['entity-name'] ?? "",
        description =
            Map<String, String>.from(json['entity-description'] ?? {}),
        metadataOrigin = json['meta'] ?? "",
        votingProcessContractAddress = json['voting-contract'],
        gatewayUpdate = json['gateway-update'] ?? {},
        newsFeed = json['news-feed'] ?? {},
        activeProcessIds = ((json['process-ids'] ?? {})['active'] ?? [])
            .cast<String>()
            .toList(),
        endedProcessIds = ((json['process-ids'] ?? {})['ended'] ?? [])
            .cast<String>()
            .toList(),
        avatar = json['avatar'],
        gatewayBootNodes =
            (json['gateway-boot-nodes'] ?? []).cast<String>().toList(),
        relays = (json['relays'] ?? []).cast<String>().toList(),
        actions = json['actions'] ?? [];

  Map<String, dynamic> toJson() {
    return {
      // global
      'resolverAddress': resolverAddress,
      'entityId': entityId,
      'networkId': networkId,
      'entryPoints': entryPoints,
      // meta
      'languages': languages,
      'entity-name': name,
      'entity-description': description,
      'meta': metadataOrigin,
      'voting-contract': votingProcessContractAddress,
      'gateway-update': gatewayUpdate,
      'news-feed': newsFeed,
      'process-ids': {'active': activeProcessIds, 'ended': endedProcessIds},
      'avatar': avatar,
      'gateway-boot-nodes': gatewayBootNodes,
      'relays': relays,
      'actions': actions
    };
  }
}
