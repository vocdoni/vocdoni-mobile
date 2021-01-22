import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:flutter/material.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/unlockPattern/drawPattern.dart';
import 'package:vocdoni/lib/pattern.dart';
import 'package:vocdoni/constants/settings.dart';

/// This component prompts for a visual lock patten, which is transformed into a passphrase.
/// The component will attempt to decrypt `encryptedText`. If it succeeds, the
/// passphrase will be returned via the router as a string.
class PatternPromptModal extends StatefulWidget {
  final AccountModel account; // to unlock

  PatternPromptModal(this.account);

  @override
  _PatternPromptModalState createState() => _PatternPromptModalState();
}

class _PatternPromptModalState extends State<PatternPromptModal> {
  int minLength = 5;
  int maxLength = 100;
  double widthSize = 300;
  double dotRadius = 5;
  double hitRadius = 20;
  int toasterDuration = 3;
  Color hitColor = Colors.transparent;
  Color patternColor = colorBlue;

  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("AccountUnlock");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        title: " ",
        showBackButton: true,
        onBackButton: onCancel,
      ),
      body: Builder(
        builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 3),
              Section(
                withDectoration: false,
                text: getText(context, "main.unlockName").replaceFirst(
                    "{{NAME}}", widget.account.identity.value.alias),
              ),
              Spacer(),
              Center(
                child: buildConfirming(context),
              ),
              Spacer(),
            ]),
      ),
    );
  }

  onCancel() {
    Navigator.pop(context, null);
  }

  DrawPattern buildConfirming(BuildContext context) {
    // TODO: Implement exponential back-off

    return DrawPattern(
      key: Key("ConfirmPattern"),
      gridSize: PATTERN_GRID_SIZE,
      widthSize: widthSize,
      dotRadius: dotRadius,
      hitRadius: hitRadius,
      hitColor: hitColor,
      canRepeatDot: false,
      patternColor: patternColor,
      dotColor: colorDescription,
      canDraw: true,
      onPatternStarted: onPatternStart,
      onPatternStopped: (_, dots) => onPatternStop(context, dots),
      onDotHaptic: HapticFeedback.mediumImpact,
    );
  }

  void onPatternStart(BuildContext context) {
    setState(() {
      patternColor = colorBlue;
    });
  }

  onPatternStop(BuildContext context, List<int> pattern) async {
    try {
      final encryptedText =
          widget.account.identity.value.keys[0].encryptedMnemonic;
      // check if we can decrypt it

      final passphrase = patternToString(pattern, gridSize: PATTERN_GRID_SIZE);
      final decryptedPayload =
          await Symmetric.decryptStringAsync(encryptedText, passphrase);

      if (decryptedPayload == null)
        throw InvalidPatternError("The decryption key is invalid");

      if (!mounted) return;

      // OK
      Navigator.pop(context, passphrase);
      widget.account.trackSuccessfulAuth().catchError((_) {});
    } catch (err) {
      await widget.account.trackFailedAuth();
      if (!mounted) return;

      setState(() {
        patternColor = colorRed;
      });

      Navigator.pop(
          context, InvalidPatternError("main.thePatternYouEnteredIsNotValid"));
    }
  }
}
