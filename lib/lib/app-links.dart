import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/view-modals/sign-modal.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/widgets/toast.dart'; // for kReleaseMode

// /////////////////////////////////////////////////////////////////////////////
// MAIN
// /////////////////////////////////////////////////////////////////////////////

Future handleIncomingLink(Uri newLink, BuildContext scaffoldBodyContext) async {
  if (!(newLink is Uri)) throw Exception();

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> indicator;

  try {
    switch (newLink.path) {
      case "/entity":
        indicator =
            showLoading("Please, wait...", context: scaffoldBodyContext);
        await fetchAndShowEntity(
            entityId: newLink.queryParameters["entityId"],
            entryPoints: newLink.queryParametersAll["entryPoints[]"],
            context: scaffoldBodyContext);
        indicator.close();
        break;
      case "/signature":
        await showSignatureScreen(
            payload: newLink.queryParameters["payload"],
            returnUri: newLink.queryParameters["returnUri"],
            context: scaffoldBodyContext);
        break;
      default:
        if (!kReleaseMode)
          throw LinkingError(
              "Invalid path"); // Throw on debug, ignore on release
    }
  } catch (err) {
    if (indicator != null) indicator.close();
    throw err;
  }
}

// /////////////////////////////////////////////////////////////////////////////
// HANDLERS
// /////////////////////////////////////////////////////////////////////////////
Future fetchAndShowEntity(
    {@required String entityId, @required List<String> entryPoints, @required BuildContext context}) async {
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

  EntityReference entityRef = EntityReference();
  entityRef.entityId = entityId;
  entityRef.entryPoints.addAll(validEntryPoints);

  final entityModel = EntityModel(entityRef);

  try {
    // fetch metadata from the reference. The view will fetch the rest.
    await entityModel.refreshMetadata();

    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    // subscribe if not already
    await currentAccount.subscribe(entityModel);
    Navigator.pushNamed(context, "/entity", arguments: entityModel);
  } catch (err) {
    // showMessage("Could not fetch the entity details",
    //     context: context, purpose: Purpose.DANGER);
    throw Exception("Could not fetch the entity details");
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
