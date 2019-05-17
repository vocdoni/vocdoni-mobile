import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';

class IdentityWelcome extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
        body: Center(
      child: Align(
        alignment: Alignment(0, -0.3),
        child: Container(
          constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
          color: Color(0x00ff0000),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                  child: Text("Welcome!",
                      style: new TextStyle(
                          fontSize: 30, color: Color(0xff888888)))),
              SizedBox(height: 100),
              Center(
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(hintText: "What's your name?"),
                  onSubmitted: onSubmitted,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  onSubmitted(String name) {
    debugPrint(name);
    //Navigator.pushReplacementNamed(context, "/home");
  }
}
