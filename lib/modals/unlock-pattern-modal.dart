import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/unlockPattern/drawPattern.dart';

enum SignatureType { decipherOnly, ecsda, lrs }

class UnlockPatternModal extends StatefulWidget {
  SignatureType signatureType = SignatureType.decipherOnly;
  String payloadToDecrypt;
  String payloadToSign;
  UnlockPatternModal(
      {this.payloadToDecrypt, this.signatureType = SignatureType.decipherOnly});

  @override
  _UnlockPatternModalState createState() => _UnlockPatternModalState();
}

class _UnlockPatternModalState extends State<UnlockPatternModal> {
  int minLength = 5;
  int maxLength = 100;
  double widthSize = 300;
  int gridSize = 3;
  double dotRadius = 5;
  double hitRadius = 20;
  int toasterDuration = 3;
  Color hitColor = Colors.transparent;
  Color patternColor = blueColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TopNavigation(
          title: " ",
          showBackButton: true,
          onBackButton: onCancel,
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 3),
              Section(
                withDectoration: false,
                text: "Unlock",
              ),
              Spacer(),
              Center(
                child: buildConfirming(),
              ),
              Spacer(),
            ]));
  }

  onCancel() {
    Navigator.pop(context, null);
  }

  DrawPattern buildConfirming() {
    return DrawPattern(
      key: Key("ConfirmPattern"),
      gridSize: gridSize,
      widthSize: widthSize,
      dotRadius: dotRadius,
      hitRadius: hitRadius,
      hitColor: hitColor,
      canRepeatDot: false,
      patternColor: patternColor,
      dotColor: descriptionColor,
      canDraw: true,
      onPatternStarted: onPatternStarted,
      onPatternStopped: onPatternStopped,
    );
  }

  void onPatternStarted(BuildContext context) {
    setState(() {
      patternColor = blueColor;
    });
  }

  void onPatternStopped(BuildContext context, List<int> pattern) {
    String key = patternToString(pattern);
    String decryptedPayload  = decrypt(key, widget.payloadToDecrypt);

    if (decryptedPayload != null)
    {
      Navigator.pop(context, decryptedPayload);
      return;
    }

    setState(() {
      patternColor = redColor;
    });

    showErrorMessage("Wrong pattern",
        context: context, duration: toasterDuration);
    return;
  }

  String patternToString(List<int> pattern) {
    String stringPattern = "";
    for (int i = 0; i < pattern.length - 1; i++) {
      stringPattern += (pattern[i].toRadixString(gridSize * gridSize));
    }
    return stringPattern;
  }

  String decrypt(String key, String payload) {
    return null;
  }
}
