import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:native_widgets/native_widgets.dart';

void showMessage(String text, BuildContext context, {Function onPressed}) {
  if (text == null)
    throw ("No text");
  else if (context == null) throw ("No context");

  final snackBar = SnackBar(
    content: Text(text),
    action: SnackBarAction(
      label: 'OK',
      // textColor: Colors.white,
      onPressed: onPressed ?? () {},
    ),
  );

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  Scaffold.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

void showSuccessMessage(String text, BuildContext context,
    {Function onPressed}) {
  if (text == null)
    throw ("No text");
  else if (context == null) throw ("No context");

  final snackBar = SnackBar(
    content: Text(text),
    backgroundColor: successColor,
    action: SnackBarAction(
      label: 'OK',
      textColor: Colors.white,
      onPressed: onPressed ?? () {},
    ),
  );

  // Find the Scaffold in the Widget tree and use it to show a SnackBar
  Scaffold.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

void showErrorMessage(String text, BuildContext context, {Function onPressed}) {
  if (text == null)
    throw ("No text");
  else if (context == null) throw ("No context");

  final snackBar = SnackBar(
    content: Text(text),
    backgroundColor: dangerColor,
    duration: Duration(seconds: 10),
    action: SnackBarAction(
      label: 'OK',
      textColor: Colors.white,
      onPressed: onPressed ?? () {},
    ),
  );

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  Scaffold.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

showLoading(String text, BuildContext context) {
  if (text == null)
    throw ("No text");
  else if (context == null) throw ("No context");

  final loadingSnackBar = SnackBar(
    duration: Duration(seconds: 30),
    content: Row(
      children: <Widget>[
        NativeLoadingIndicator(),
        Padding(padding: EdgeInsets.only(left: 10), child: Text(text))
      ],
    ),
  );
  Scaffold.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(loadingSnackBar);
}

void hideLoading(BuildContext context) {
  Scaffold.of(context).hideCurrentSnackBar();
}
