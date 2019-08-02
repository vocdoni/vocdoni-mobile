import "package:flutter/material.dart";
import 'package:vocdoni/lang/index.dart';

Future showAlert(
    {String title, String text, String okButton, BuildContext context}) {
  if (text == null)
    throw FlutterError("No text");
  else if (context == null) throw FlutterError("No context");

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title ?? "Vocdoni"),
        content: Text(text),
        actions: [
          FlatButton(
            child: Text(okButton ?? Lang.of(context).get("OK")),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    },
  );
}

Future showPrompt(
    {String title,
    String text,
    String okButton,
    String cancelButton,
    BuildContext context}) {
  if (text == null)
    throw FlutterError("No text");
  else if (context == null) throw FlutterError("No context");

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title ?? "Vocdoni"),
        content: Text(text),
        actions: [
          FlatButton(
            child: Text(cancelButton ?? Lang.of(context).get("Cancel")),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text(okButton ?? Lang.of(context).get("OK")),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    },
  );
}
