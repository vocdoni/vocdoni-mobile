import "package:flutter/material.dart";

Future<Null> showAlert(
    {String title, String text, String okButton = "OK", BuildContext context}) {
  if (text == null)
    throw ("No text");
  else if (context == null) throw ("No context");

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title != null ? Text(title) : Text(""),
        content: Text(text),
        actions: [
          FlatButton(
            child: Text(okButton),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    },
  );
}
