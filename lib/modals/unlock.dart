import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/widgets/unlockPattern.dart';

class Unlock extends StatefulWidget {
  @override
  _UnlockState createState() => _UnlockState();
}

class _UnlockState extends State<Unlock> {
 
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
        appBar: AppBar(
          title: Text("Vocdoni"),
        ),
        body:UnlockPattern(gridSize: 3,),
    );
  }
}