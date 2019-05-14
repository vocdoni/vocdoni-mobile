import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

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
  Scaffold.of(context).showSnackBar(snackBar);
}

void showErrorMessage(String text, BuildContext context, {Function onPressed}) {
  if (text == null)
    throw ("No text");
  else if (context == null) throw ("No context");

  final snackBar = SnackBar(
    content: Text(text),
    backgroundColor: dangerColor,
    action: SnackBarAction(
      label: 'OK',
      textColor: Colors.white,
      onPressed: onPressed ?? () {},
    ),
  );

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  Scaffold.of(context).showSnackBar(snackBar);
}
