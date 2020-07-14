import 'package:dvote/dvote.dart';
import 'package:dvote_common/flavors/config.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/view-modals/sign-modal.dart';
import 'package:flutter/foundation.dart';
import 'package:dvote_common/widgets/toast.dart'; // for kReleaseMode

// /////////////////////////////////////////////////////////////////////////////
// / MAIN
// /////////////////////////////////////////////////////////////////////////////

Future handleIncomingLink(Uri newLink, BuildContext scaffoldBodyContext) async {
  if (!(newLink is Uri)) throw Exception();

  // Accepted domains:
  // - app.vocdoni.net, app.dev.vocdoni.net => Use as they are
  // - vocdoni.page.link, vocdonidev.page.link => Extract the `link` parameter

  if (newLink.host == "vocdoni.page.link" ||
      newLink.host == "vocdonidev.page.link") {
    final extractedUrl = newLink.queryParameters["link"];
    newLink = Uri.parse(extractedUrl);
  }

  if (newLink.pathSegments.length < 1) {
    if (kReleaseMode)
      throw Exception();
    else
      return;
  }
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> indicator;

  final pathSegments = newLink.pathSegments
      .where((str) => str.length > 0)
      .cast<String>()
      .toList();
  final hashSegments = newLink.fragment
      .split("/")
      .where((str) => str.length > 0)
      .cast<String>()
      .toList();

  try {
    switch (pathSegments[0]) {
      case "entities":
        indicator = showLoading(getText(scaffoldBodyContext, "Please, wait..."),
            context: scaffoldBodyContext);
        await handleEntityLink(pathSegments, hashSegments,
            context: scaffoldBodyContext);
        indicator.close();
        break;
      // case "signature":
      //   await showSignatureScreen(
      //       payload: newLink.queryParameters["payload"],
      //       returnUri: newLink.queryParameters["returnUri"],
      //       context: scaffoldBodyContext);
      //   break;
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
// / HANDLERS
// /////////////////////////////////////////////////////////////////////////////

Future handleEntityLink(List<String> pathSegments, List<String> hashSegments,
    {@required BuildContext context}) async {
  // Possible values:
  // https://dev.vocdoni.link/entities/0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46
  // https://app.vocdoni.dev/entities/#/0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46

  String entityId;
  if (pathSegments.length >= 2 &&
      pathSegments[1] is String &&
      RegExp(r"^0x[a-zA-Z0-9]{64}$").hasMatch(pathSegments[1])) {
    entityId = pathSegments[1];
  } else if (hashSegments[0] is String &&
      RegExp(r"^0x[a-zA-Z0-9]{64}$").hasMatch(hashSegments[0])) {
    entityId = hashSegments[0];
  }

  if (!(entityId is String)) {
    throw LinkingError("Invalid entityId");
  }
  // } else if (!(entryPoints is List) || entryPoints.length == 0) {
  //   throw LinkingError("Invalid entryPoints");

  // List<String> validEntryPoints = entryPoints
  //     .map((String uri) {
  //       try {
  //         return Uri.decodeFull(uri);
  //       } catch (err) {
  //         throw LinkingError("Invalid entry point URI");
  //       }
  //     })
  //     .where((uri) => uri != null)
  //     .toList();

  EntityReference entityRef = EntityReference();
  entityRef.entityId = entityId;
  // entityRef.entryPoints.addAll(validEntryPoints);

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
    throw Exception(getText(context, "Could not fetch the entity details"));
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

// /////////////////////////////////////////////////////////////////////////////
// / GENERATORS
// /////////////////////////////////////////////////////////////////////////////

String generateEntityLink(String entityId) {
  final domain = FlavorConfig.instance.constants.linkingDomain;
  return "https://$domain/entities/$entityId";
}
