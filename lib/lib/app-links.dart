import 'package:dvote/dvote.dart';
import 'package:dvote_common/flavors/config.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:flutter/foundation.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:vocdoni/views/register-validation-page.dart'; // for kReleaseMode

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
        await handleEntityLink(hashSegments, context: scaffoldBodyContext);
        indicator.close();
        break;
      case "validation":
        indicator = showLoading(getText(scaffoldBodyContext, "Please, wait..."),
            context: scaffoldBodyContext);
        await handleValidationLink(hashSegments, context: scaffoldBodyContext);
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

Future handleEntityLink(List<String> hashSegments,
    {@required BuildContext context}) async {
  // Possible values:
  // https://app.vocdoni.net/entities/#/0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46
  // https://app.dev.vocdoni.net/entities/#/0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46

  String entityId;
  if (hashSegments[0] is String &&
      RegExp(r"^0x[a-zA-Z0-9]{40,64}$").hasMatch(hashSegments[0])) {
    entityId = hashSegments[0];
  }

  if (!(entityId is String)) {
    throw LinkingError("Invalid entityId");
  }

  EntityReference entityRef = EntityReference();
  entityRef.entityId = entityId;

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

Future handleValidationLink(List<String> hashSegments,
    {@required BuildContext context}) async {
  // Possible values:
  // https://app.vocdoni.net/validation/#/0x-entity-id/0x-token
  // https://app.dev.vocdoni.net/validation/#/0x-entity-id/0x-token

  if (hashSegments.length < 2 ||
      !(hashSegments[0] is String) ||
      !(hashSegments[1] is String)) {
    throw LinkingError("Invalid validation link");
  } else if (!RegExp(r"^0x[a-zA-Z0-9]{40,64}$").hasMatch(hashSegments[0]) ||
      !RegExp(r"^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$")
          .hasMatch(hashSegments[1])) {
    throw LinkingError("Invalid validation link");
  }

  final entityId = hashSegments[0];
  final validationToken = hashSegments[1];

  EntityReference entityRef = EntityReference();
  entityRef.entityId = entityId;

  final entityModel = EntityModel(entityRef);

  try {
    // fetch metadata from the reference. The view will fetch the rest.
    await entityModel.refreshMetadata();

    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    // subscribe if not already
    await currentAccount.subscribe(entityModel);

    final name = entityModel.metadata.value?.name["default"];
    if (!(name is String)) throw Exception("Invalid entity data");
    final uri = entityModel.metadata.value?.actions[0]?.url;
    if (!(uri is String) || uri.length < 1)
      throw Exception("Invalid entity data");

    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => RegisterValidationPage(
                entityId: entityId,
                entityName: name,
                backendUri: uri,
                validationtoken: validationToken)));
  } catch (err) {
    throw Exception(getText(context, "Could not fetch the entity details"));
  }
}

// showSignatureScreen(
//     {@required BuildContext context,
//     @required String payload,
//     @required String returnUri}) {
//   if (!(payload is String) || payload.length == 0) {
//     throw LinkingError("Invalid payload");
//   } else if (!(returnUri is String) || returnUri.length == 0) {
//     throw LinkingError("Invalid returnUri");
//   }

//   payload = Uri.decodeFull(payload);
//   final rtnUri = Uri.parse(returnUri);
//   if (rtnUri == null) throw LinkingError("Invalid return URI");

//   final SignModalArguments args =
//       SignModalArguments(payload: payload, returnUri: rtnUri);

//   Navigator.pushNamed(context, "/signature", arguments: args);
// }

// /////////////////////////////////////////////////////////////////////////////
// / GENERATORS
// /////////////////////////////////////////////////////////////////////////////

String generateEntityLink(String entityId) {
  final domain = FlavorConfig.instance.constants.linkingDomain;
  return "https://$domain/entities/$entityId";
}
