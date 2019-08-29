import 'package:dvote/models/dart/entity.pbserver.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/modals/sign-modal.dart';
// import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode

// /////////////////////////////////////////////////////////////////////////////
// MAIN
// /////////////////////////////////////////////////////////////////////////////

Future handleIncomingLink(Uri newLink, BuildContext context) async {
  if (!(newLink is Uri)) return null;

  switch (newLink.path) {
    case "/entity":
      return fetchAndShowEntity(
          entityId: newLink.queryParameters["entityId"],
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
        throw LinkingError("Invalid path"); // Throw on debug, ignore on release
  }
}

// /////////////////////////////////////////////////////////////////////////////
// HANDLERS
// /////////////////////////////////////////////////////////////////////////////

Future fetchAndShowEntity(
    {String entityId, List<String> entryPoints, BuildContext context}) async {
  if (!(entityId is String) ||
      !RegExp(r"^0x[a-zA-Z0-9]{64}$").hasMatch(entityId)) {
    throw LinkingError("Invalid entityId");
  } else if (!(entryPoints is List) || entryPoints.length == 0) {
    throw LinkingError("Invalid entryPoints");
  }

  List<String> validEntryPoints = entryPoints
      .map((String uri) {
        try {
          return Uri.decodeFull(uri);
        } catch (err) {
          throw LinkingError("Invalid entry point URI");
        }
      })
      .where((uri) => uri != null)
      .toList();

  EntityReference entityRef =
      makeEntityReference(entityId: entityId, entryPoints: validEntryPoints);

  showLoading(Lang.of(context).get("Connecting..."), global: true);

  try {
    final entityMetadata = await fetchEntityData(entityRef);

    if (entityMetadata == null)
      throw LinkingError("Could not fetch the details");

    hideLoading(global: true);

    // Show screen
    Navigator.pushNamed(context, "/entity", arguments: entityMetadata);
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
    throw LinkingError("Invalid payload");
  } else if (!(returnUri is String) || returnUri.length == 0) {
    throw LinkingError("Invalid returnUri");
  }

  payload = Uri.decodeFull(payload);
  final rtnUri = Uri.parse(returnUri);
  if (rtnUri == null) throw LinkingError("Invalid return URI");

  final SignModalArguments args =
      SignModalArguments(payload: payload, returnUri: rtnUri);

  Navigator.pushNamed(context, "/signature", arguments: args);
}

// ////////////////////////////////////////////////////////////////////////////
// UTILITIES
// ////////////////////////////////////////////////////////////////////////////

class LinkingError implements Exception {
  final String msg;
  const LinkingError(this.msg);
  String toString() => 'LinkingError: $msg';
}
