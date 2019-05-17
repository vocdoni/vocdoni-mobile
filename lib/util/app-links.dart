import 'package:flutter/material.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/modals/confirm-entity-subscription.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/widgets/toast.dart';

///////////////////////////////////////////////////////////////////////////////
// MAIN
///////////////////////////////////////////////////////////////////////////////

Future<String> handleIncomingLink(Uri newLink, BuildContext context) async {
  if (!(newLink is Uri)) return null;

  switch (newLink.path) {
    case "/subscribe":
      return handleEntitySubscription(
          resolverAddress: newLink.queryParameters["resolverAddress"],
          entityId: newLink.queryParameters["entityId"],
          networkId: newLink.queryParameters["networkId"],
          entryPoints: newLink.queryParametersAll["entryPoints[]"],
          context: context);
      break;
    default:
      throw ("Invalid path");
  }
}

///////////////////////////////////////////////////////////////////////////////
// HANDLERS
///////////////////////////////////////////////////////////////////////////////

Future<String> handleEntitySubscription(
    {String resolverAddress,
    String entityId,
    String networkId,
    List<String> entryPoints,
    BuildContext context}) async {
  if (!(resolverAddress is String) ||
      !RegExp(r"^0x[a-zA-Z0-9]{40}$").hasMatch(resolverAddress)) {
    throw ("Invalid resolverAddress");
  } else if (!(entityId is String) ||
      !RegExp(r"^0x[a-zA-Z0-9]{64}$").hasMatch(entityId)) {
    throw ("Invalid entityId");
  } else if (!(networkId is String) ||
      !RegExp(r"^[0-9]+$").hasMatch(networkId)) {
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

  showLoading(Lang.of(context).get("Connecting..."), global: true);

  try {
    // Fetch organization data
    Organization org = await fetchOrganizationInfo(
        resolverAddress, entityId, networkId, decodedEntryPoints);

    hideLoading(global: true);

    // Show approval screen
    final accept = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ConfirmEntitySubscriptionModal(org)));

    if (accept != true) {
      return null;
    }
    await identitiesBloc.subscribe(org);
  } catch (err) {
    hideLoading(global: true);

    throw err;
  }

  return Lang.of(context).get("The subscription has been registered");
}
