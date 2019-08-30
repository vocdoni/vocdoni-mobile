import 'package:dvote/models/dart/entity.pbserver.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/modals/sign-modal.dart';
// import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
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
          //TODO: Needs to be resolved via ENS
          resolverAddress:
              '0xcabc15238ac8eafe46e8bd58d9a3af1c8a0e855a', //newLink.queryParameters["resolverAddress"],
          entityId: newLink.queryParameters["entityId"],
          networkId: account.networkId, //newLink.queryParameters["networkId"],
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
//TODO Make use of entryPoints;
/*
  List<String> decodedEntryPoints = entryPoints
      .map((String uri) {
        try {
          return Uri.decodeFull(uri);
        } catch (err) {
          throw LinkingError("Invalid entry point URI");
        }
      })
      .where((uri) => uri != null)
      .toList();
*/

  EntityReference entitySummary = makeEntityReference(
      entityId: entityId,
      resolverAddress: resolverAddress,
      entryPoints: []);

  final ent = new Ent(entitySummary);
  Navigator.pushNamed(context, "/entity", arguments: ent);
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
