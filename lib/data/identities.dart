import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "dart:convert";
import "dart:async";

import 'package:vocdoni/util/singletons.dart';
// import 'package:vocdoni/util/api.dart';

/// STORAGE STRUCTURE
/// - SharedPreferences > "accounts" > String List > address (String)
/// - SecureStorage > {account-address} > { mnemonic, publicKey, alias }
/// - SharedPreferences > "{account-address}/organizations" > String List > { name, ... }

final secStore = new FlutterSecureStorage();

class IdentitiesBloc {
  BehaviorSubject<List<Identity>> _state =
      BehaviorSubject<List<Identity>>.seeded(List<Identity>());

  Observable<List<Identity>> get stream => _state.stream;
  List<Identity> get current => _state.value;

  Future restore() async {
    return readState();
  }

  /// Read and construct the data structures (without the private data/mnemonic)
  Future readState() async {
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
      if (prefs.containsKey("$addr/organizations")) {
        orgs = prefs.getStringList("$addr/organizations");
      }

      // Intentionally skip the mnemonic
      return Identity(
        publicKey: decoded["publicKey"],
        alias: decoded["alias"],
        // TODO: REMOVE
        mnemonic:
            "This Mnemonic Is Fake Because Is Not Encrypted This Mnemonic Is Fake Because Is Not Encrypted One Two",
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

  Future refreshSubscriptions() {
    // TODO: refresh for the selected identity
  }

  // Operations

  /// Registers a new identity with an empty list of organizations
  Future create(
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

    List<String> currentAddrs;
    if (prefs.containsKey("accounts")) {
      currentAddrs = prefs.getStringList("accounts");
      if (currentAddrs.length > 0) {
        // Check unique addr, alias
        await Future.wait(currentAddrs.map((addr) async {
          if (addr == address) throw ("The account already exists");

          final strIdent = await secStore.read(key: addr);
          final decoded = jsonDecode(strIdent);
          if (decoded is Map &&
              decoded["alias"] is String &&
              (decoded["alias"] as String).trim() == alias.trim()) {
            throw ("The account already exists");
          }
        }));

        currentAddrs.add(address);
        await prefs.setStringList("accounts", currentAddrs);
      } else {
        currentAddrs = [address];
        await prefs.setStringList("accounts", currentAddrs);
      }
    } else {
      currentAddrs = [address];
      await prefs.setStringList("accounts", currentAddrs);
    }

    // ADD A SERIALIZED WALLET FOR THE ADDRESS
    await secStore.write(
      key: address,
      value: json.encode({
        "mnemonic": mnemonic,
        "publicKey": publicKey,
        "alias": alias.trim()
      }),
    );

    // ADD AN EMPTY LIST OF ORGANIZATIONS
    await prefs.setStringList("$address/organizations", []);

    // Refresh state
    await readState();

    // Set the new identity as active
    appStateBloc.selectIdentity(currentAddrs.length - 1);
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
    if (prefs.containsKey("$address/organizations")) {
      accountOrganizations = prefs.getStringList("$address/organizations");
    }

    final already = accountOrganizations.any((strOrganization) {
      final org = Organization.fromJson(jsonDecode(strOrganization));
      if (!(org is Organization)) return false;
      return org.entityId == newOrganization.entityId;
    });
    if (already) throw ("Already subscribed");

    accountOrganizations.add(json.encode(newOrganization.toJson()));
    await prefs.setStringList("$address/organizations", accountOrganizations);

    appStateBloc.selectOrganization(accountOrganizations.length - 1);

    // Refresh state
    await readState();

    // Fetch after the organization is registered
    newsFeedsBloc.fetchOrganizationFeeds(newOrganization);
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
  final Map<String, String> newsFeed; // language dependent
  final String avatar;
  final String imageHeader;
  Map<String, dynamic> gatewayUpdate = {}; // unused
  List gatewayBootNodes = []; // unused by now
  List relays = []; // unused by now
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
      this.avatar,
      this.imageHeader});

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
        newsFeed = Map<String, String>.from(json['news-feed'] ?? {}),
        activeProcessIds = ((json['process-ids'] ?? {})['active'] ?? [])
            .cast<String>()
            .toList(),
        endedProcessIds = ((json['process-ids'] ?? {})['ended'] ?? [])
            .cast<String>()
            .toList(),
        avatar = json['avatar'],
        imageHeader = json['imageHeader'],
        gatewayBootNodes = json['gateway-boot-nodes'] ?? [],
        relays = json['relays'] ?? [],
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
      'imageHeader':imageHeader,
      'gateway-boot-nodes': gatewayBootNodes,
      'relays': relays,
      'actions': actions
    };
  }
}
