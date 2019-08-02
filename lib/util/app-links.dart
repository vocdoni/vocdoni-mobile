import 'package:flutter/material.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/modals/sign-modal.dart';
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
    case "/signature":
      return showSignatureScreen(
          payload: newLink.queryParameters["payload"],
          returnUri: newLink.queryParameters["returnUri"],
          context: context);
    default:
      if (!kReleaseMode)
        throw FlutterError("Invalid path"); // Throw on debug, ignore on release
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
    throw FlutterError("Invalid resolverAddress");
  } else if (!(entityId is String) ||
      !RegExp(r"^0x[a-zA-Z0-9]{64}$").hasMatch(entityId)) {
    throw FlutterError("Invalid entityId");
  } else if (!(networkId is String) ||
      !RegExp(r"^[0-9a-zA-Z]+$").hasMatch(networkId)) {
    throw FlutterError("Invalid networkId");
  } else if (!(entryPoints is List) || entryPoints.length == 0) {
    throw FlutterError("Invalid entryPoints");
  }

  List<String> decodedEntryPoints = entryPoints
      .map((String uri) {
        try {
          return Uri.decodeFull(uri);
        } catch (err) {
          throw FlutterError("Invalid entry point URI");
        }
      })
      .where((uri) => uri != null)
      .toList();

  showLoading(Lang.of(context).get("Connecting..."), global: true);

  try {
    // Fetch organization data
    final org = await fetchEntityData(
        resolverAddress, entityId, networkId, decodedEntryPoints);
    if (org == null) throw FlutterError("Could not fetch the details");

    hideLoading(global: true);

    // Show screen
    Navigator.pushNamed(context, "/organization", arguments: org);
  } catch (err) {
    hideLoading(global: true);

    throw err;
  }
}

showSignatureScreen(
    {@required BuildContext context,
    @required String payload,
    @required String returnUri}) {
  if (!(payload is String) || payload.length == 0) {
    throw FlutterError("Invalid payload");
  } else if (!(returnUri is String) || returnUri.length == 0) {
    throw FlutterError("Invalid returnUri");
  }

  payload = Uri.decodeFull(payload);
  final rtnUri = Uri.parse(returnUri);
  if (rtnUri == null) throw FlutterError("Invalid return URI");

  final SignModalArguments args = SignModalArguments(payload: payload, returnUri: rtnUri);

  Navigator.pushNamed(context, "/signature", arguments: args);
}
