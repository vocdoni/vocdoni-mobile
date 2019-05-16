import 'package:flutter/material.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';

///////////////////////////////////////////////////////////////////////////////
// MAIN
///////////////////////////////////////////////////////////////////////////////

Uri lastHandledLink;

Future handleIncomingLink(Uri newLink, BuildContext context) async {
  if (!(newLink is Uri))
    return;
  else if (newLink.toString() == lastHandledLink?.toString()) return;

  switch (newLink.path) {
    case "/subscribe":
      await handleEntitySubscription(
          resolverAddress: newLink.queryParameters["resolverAddress"],
          entityId: newLink.queryParameters["entityId"],
          networkId: newLink.queryParameters["networkId"],
          entryPoints: newLink.queryParametersAll["entryPoints[]"],
          context: context);
      break;
    default:
      throw ("Invalid path");
  }

  lastHandledLink = newLink;
}

///////////////////////////////////////////////////////////////////////////////
// HANDLERS
///////////////////////////////////////////////////////////////////////////////

Future handleEntitySubscription(
    {String resolverAddress,
    String entityId,
    String networkId,
    List<String> entryPoints,
    BuildContext context}) async {
  if (!(resolverAddress is String) ||
      RegExp(r"^0x[a-zA-Z0-9]{40}$").hasMatch(resolverAddress)) {
    throw ("Invalid resolverAddress");
  } else if (!(entityId is String) ||
      RegExp(r"^0x[a-zA-Z0-9]{64}$").hasMatch(entityId)) {
    throw ("Invalid entityId");
  } else if (!(networkId is String) ||
      RegExp(r"^[0-9]+$").hasMatch(networkId)) {
    throw ("Invalid networkId");
  } else if (!(entryPoints is List) || entryPoints.length == 0) {
    throw ("Invalid entryPoints");
  }

  List<String> decodedEntryPoints = entryPoints
      .map((String uri) {
        try {
          return Uri.decodeFull(uri);
        } catch (err) {
          throw ("Invalid entry point URI");
        }
      })
      .where((uri) => uri != null)
      .toList();

  // Fetch organization data
  Organization org = await fetchOrganizationInfo(resolverAddress, entityId, networkId, decodedEntryPoints);

  // TODO: SHOW MODAL APPROVAL SCREEN

  // TODO: SEND DIGESTED DATA TO STORE

  return identitiesBloc.subscribe(org);
}
