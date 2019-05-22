import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class BaseButton extends StatelessWidget {
  final String text;
  final Icon icon;
  final Color color;

  const BaseButton({this.text, this.icon, this.color});


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red,
      borderOnForeground: true,
      //borderRadius: BorderRadius.circular(8.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(width: 2.0, color: Colors.lightBlue.shade900)),
      elevation: 5,
      child: InkWell(
        onTap: () => print("Tap!"),
        child: SizedBox(
          width: 50.0,
          height: 48.0,
          child: Center(
            child: Text("Tap me!"),
          ),
        ),
      ),
    );
  }
}
