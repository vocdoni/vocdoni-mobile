import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/app-config.dart';
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

  // DEEP LINKS
  // - app.vocdoni.net, app.dev.vocdoni.net => Use as they are
  //    - https://<domain>/entities/#/0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46
  //    - https://<domain>/validation/#/0x-entity-id/0x-token
  // - vocdoni.page.link, vocdonidev.page.link => Extract the `link` parameter

  // QR SCAN LINKS
  // - vocdoni.link, dev.vocdoni.link
  //    - https://vocdoni.link/entities/0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46
  //    - https://vocdoni.link/validation/0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46/token-1234

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

  // Merge path and hash segments
  final pathSegments = newLink.pathSegments
      .where((str) => str.length > 0)
      .cast<String>()
      .toList();
  final hashSegments = newLink.fragment
      .split("/")
      .where((str) => str.length > 0)
      .cast<String>()
      .toList();

  final allSegments = <String>[];
  allSegments.addAll(pathSegments);
  allSegments.addAll(hashSegments);

  // Just open the app, do nothing
  if (allSegments.length == 0) return;

  try {
    switch (allSegments[0]) {
      case "entities":
        indicator = showLoading(getText(scaffoldBodyContext, "main.pleaseWait"),
            context: scaffoldBodyContext);
        await handleEntityLink(allSegments.skip(1).toList(),
            context: scaffoldBodyContext);
        indicator.close();
        break;
      case "validation":
        indicator = showLoading(getText(scaffoldBodyContext, "main.pleaseWait"),
            context: scaffoldBodyContext);
        await handleValidationLink(allSegments.skip(1).toList(),
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
        throw LinkingError("Invalid path");
    }
  } catch (err) {
    if (indicator != null) indicator.close();
    throw err;
  }
}

// /////////////////////////////////////////////////////////////////////////////
// / HANDLERS
// /////////////////////////////////////////////////////////////////////////////

Future handleEntityLink(List<String> paramSegments,
    {@required BuildContext context}) async {
  // paramSegments => [ "0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46" ]

  String entityId;
  if (paramSegments[0] is String &&
      RegExp(r"^0x[a-zA-Z0-9]{40,64}$").hasMatch(paramSegments[0])) {
    entityId = paramSegments[0];
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
    // showMessage("error.couldNotFetchTheEntityDetails",
    //     context: context, purpose: Purpose.DANGER);
    throw Exception(getText(context, "error.couldNotFetchTheEntityDetails"));
  }
}

Future handleValidationLink(List<String> paramSegments,
    {@required BuildContext context}) async {
  // paramSegments => [ "0x462fc85288f9b204d5a146901b2b6a148bddf0ba1a2fb5c87fb33ff22891fb46", "token-1234" ]

  if (paramSegments.length < 2 ||
      !(paramSegments[0] is String) ||
      !(paramSegments[1] is String)) {
    throw LinkingError("Invalid validation link");
  } else if (!RegExp(r"^0x[a-zA-Z0-9]{40,64}$").hasMatch(paramSegments[0]) ||
      !RegExp(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
          .hasMatch(paramSegments[1])) {
    throw LinkingError("Invalid validation link");
  }

  final entityId = paramSegments[0];
  final validationToken = paramSegments[1];

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
                validationToken: validationToken)));
  } catch (err) {
    throw Exception(getText(context, "error.couldNotFetchTheEntityDetails"));
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
  final domain = AppConfig.LINKING_DOMAIN;
  return "https://$domain/entities/$entityId";
}
