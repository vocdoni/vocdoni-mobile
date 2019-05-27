import 'package:flutter/material.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode

///////////////////////////////////////////////////////////////////////////////
// MAIN
///////////////////////////////////////////////////////////////////////////////

Future handleIncomingLink(Uri newLink, BuildContext context) async {
  if (!(newLink is Uri)) return null;

  switch (newLink.path) {
    case "/organization":
      return fetchAndShowOrganization(
          resolverAddress: newLink.queryParameters["resolverAddress"],
          entityId: newLink.queryParameters["entityId"],
          networkId: newLink.queryParameters["networkId"],
          entryPoints: newLink.queryParametersAll["entryPoints[]"],
          context: context);
      break;
    default:
      if (!kReleaseMode)
        throw ("Invalid path"); // Throw on debug, ignore on release
  }
}

///////////////////////////////////////////////////////////////////////////////
// HANDLERS
///////////////////////////////////////////////////////////////////////////////

Future fetchAndShowOrganization(
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
    if (org == null) throw ("Could not fetch the details");

    hideLoading(global: true);

    // Show screen
    Navigator.pushNamed(context, "/organization", arguments: org);
  } catch (err) {
    hideLoading(global: true);

    throw err;
  }
}
