import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/unlockPattern.dart';

class Unlock extends StatefulWidget {
  @override
  _UnlockState createState() => _UnlockState();
}

class _UnlockState extends State<Unlock> {
  int minLength = 5;
  int maxLength = 10;

  void onPatternStopped(List<int> pattern) {
    if(pattern.length<minLength)
    {
      //show "to short"
    }
    debugPrint(pattern.toString());
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vocdoni"),
      ),
      body: Center(
          child: UnlockPattern(
              gridSize: 4,
              widthSize: 250,
              dotRadius: 10,
              canRepeatDot: false,
              patternColor: blueColor,
              dotsColor: descriptionColor,
              canDraw: true,
              onPatternStopped: onPatternStopped)),
    );
  }
}
