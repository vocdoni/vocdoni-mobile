import "package:flutter/material.dart";
import 'package:vocdoni/lang/index.dart';

Future<void> showAlert(String text,
    {String title, String okButton, @required BuildContext context}) {
  assert(text is String);

  return showDialog(
    context: context,
    builder: (context) {
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

Future<bool> showPrompt(String text,
    {String title,
    String okButton,
    String cancelButton,
    @required BuildContext context}) {
  assert(text is String);

  return showDialog(
    context: context,
    builder: (context) {
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
