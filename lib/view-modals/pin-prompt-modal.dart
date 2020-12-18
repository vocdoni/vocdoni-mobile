import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/unlockPattern/enterPin.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:vocdoni/lib/pattern.dart';

import '../app-config.dart';

/// This component prompts for a visual lock patten, which is transformed into a passphrase.
/// The component will attempt to decrypt `encryptedText`. If it succeeds, the
/// passphrase will be returned via the router as a string.
class PinPromptModal extends StatefulWidget {
  final AccountModel account; // to unlock

  PinPromptModal(this.account);

  @override
  _PinPromptModalState createState() => _PinPromptModalState();
}

class _PinPromptModalState extends State<PinPromptModal> {
  int pinLength = AppConfig.pinLength;

  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("PinPrompModal");
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
              Spacer(),
              Section(
                withDectoration: false,
                text: getText(context, "main.unlockName").replaceFirst(
                    "{{NAME}}", widget.account.identity.value.alias),
              ),
              Spacer(),
              EnterPin(
                totalDigits: pinLength,
                onPinHaptic: () => HapticFeedback.mediumImpact(),
                onPinStopped: onPinEntered,
                padding: EdgeInsets.symmetric(horizontal: paddingPage),
                indicatorSpace: spaceCard * 3,
              ),
              Spacer(),
            ]),
      ),
    );
  }

  onCancel() {
    Navigator.pop(context, null);
  }

  onPinEntered(BuildContext context, List<int> pin) async {
    try {
      final encryptedText =
          widget.account.identity.value.keys[0].encryptedMnemonic;
      // check if we can decrypt it

      final passphrase = pinToString(pin);
      final decryptedPayload =
          await Symmetric.decryptStringAsync(encryptedText, passphrase);

      if (decryptedPayload == null)
        throw InvalidPatternError("The decryption key is invalid");

      // if (!mounted) return;

      // OK
      Navigator.pop(context, passphrase);
      widget.account.trackSuccessfulAuth().catchError((_) {});
    } catch (err) {
      await widget.account.trackFailedAuth();
      if (!mounted) return;

      Navigator.pop(
          context, InvalidPatternError("main.thePinYouEnteredIsNotValid"));
    }
  }
}
