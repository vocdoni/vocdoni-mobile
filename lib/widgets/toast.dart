import "package:flutter/material.dart";
import 'package:vocdoni/widgets/loading-spinner.dart';
import 'package:vocdoni/constants/colors.dart';

final toasterTextStyle =
    TextStyle(fontSize: fontSizeBase, fontWeight: fontWeightRegular);

/// Displays a snackbar on the screen.
/// `IMPORTANT`: If the `context` does not descend from a `Scaffold` the call will fail
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMessage(
    String text,
    {@required BuildContext context,
    int duration = 4,
    Function onPressed,
    Purpose purpose = Purpose.NONE}) {
  if (text == null) throw Exception("No text");

  final snackBar = SnackBar(
    content: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(text, style: toasterTextStyle),
    ),
    backgroundColor: getColorByPurpose(purpose: purpose, isPale: true),
    duration: Duration(seconds: duration),
  );

  return _displaySnackBar(snackBar, context: context);
}

/// Displays a snackbar on the screen.
/// `IMPORTANT`: If the `context` does not descend from a `Scaffold` the call will fail
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    String text,
    {@required BuildContext context}) {
  if (text == null) throw Exception("No text");

  final loadingSnackBar = SnackBar(
    duration: Duration(hours: 1),
    content: Row(
      children: <Widget>[
        LoadingSpinner(color: Colors.white),
        Padding(padding: EdgeInsets.only(left: 10), child: Text(text))
      ],
    ),
  );

  return _displaySnackBar(loadingSnackBar, context: context);
}

/// Displays a snackbar on the screen.
/// `IMPORTANT`: If the `context` does not descend from a `Scaffold` the call will fail
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _displaySnackBar(
    SnackBar snackBar,
    {@required BuildContext context}) {
  Scaffold.of(context).hideCurrentSnackBar();
  return Scaffold.of(context).showSnackBar(snackBar);
}

void hideLoading({@required BuildContext context}) {
  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  return Scaffold.of(context).hideCurrentSnackBar();
}
