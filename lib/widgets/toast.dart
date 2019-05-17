import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:native_widgets/native_widgets.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMessage(
    String text,
    {bool global,
    BuildContext context,
    String buttonText = "OK",
    int duration = 6,
    Function onPressed}) {
  if (text == null) throw ("No text");

  final snackBar = SnackBar(
    content: Text(text),
    duration: Duration(seconds: duration),
    action: SnackBarAction(
      label: buttonText,
      textColor: Colors.white,
      onPressed: onPressed ?? () {},
    ),
  );

  return _displaySnackBar(snackBar, global: global, context: context);
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessMessage(
    String text,
    {bool global,
    BuildContext context,
    String buttonText = "OK",
    int duration = 6,
    Function onPressed}) {
  if (text == null) throw ("No text");

  final snackBar = SnackBar(
    content: Text(text),
    backgroundColor: successColor,
    duration: Duration(seconds: duration),
    action: SnackBarAction(
      label: buttonText,
      textColor: Colors.white,
      onPressed: onPressed ?? () {},
    ),
  );

  return _displaySnackBar(snackBar, global: global, context: context);
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorMessage(
    String text,
    {bool global,
    BuildContext context,
    String buttonText = "OK",
    int duration = 10,
    Function onPressed}) {
  if (text == null) throw ("No text");

  final snackBar = SnackBar(
    content: Text(text),
    backgroundColor: dangerColor,
    duration: Duration(seconds: duration),
    action: SnackBarAction(
      label: buttonText,
      textColor: Colors.white,
      onPressed: onPressed ?? () {},
    ),
  );

  return _displaySnackBar(snackBar, global: global, context: context);
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    String text,
    {BuildContext context,
    bool global}) {
  if (text == null) throw ("No text");

  final loadingSnackBar = SnackBar(
    duration: Duration(seconds: 30),
    content: Row(
      children: <Widget>[
        NativeLoadingIndicator(),
        Padding(padding: EdgeInsets.only(left: 10), child: Text(text))
      ],
    ),
  );

  return _displaySnackBar(loadingSnackBar, global: global, context: context);
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _displaySnackBar(
    SnackBar snackBar,
    {bool global,
    BuildContext context}) {
  if (global == true) {
    if (homePageScaffoldKey.currentState == null)
      throw ("The global snack bar can't be shown");

    homePageScaffoldKey.currentState.hideCurrentSnackBar();
    return homePageScaffoldKey.currentState.showSnackBar(snackBar);
  } else if (context is BuildContext) {
    Scaffold.of(context).hideCurrentSnackBar();
    return Scaffold.of(context).showSnackBar(snackBar);
  }
  throw ("Either context or global = true are expected");
}

void hideLoading({BuildContext context, bool global}) {
  if (global == true) {
    if (homePageScaffoldKey.currentState == null)
      throw ("The global snack bar can't be shown");
    else
      return homePageScaffoldKey.currentState.hideCurrentSnackBar();
  } else if (context is BuildContext) {
    // Find the Scaffold in the Widget tree and use it to show a SnackBar!
    return Scaffold.of(context).hideCurrentSnackBar();
  }
  throw ("Either a context or global = true must be provided");
}
