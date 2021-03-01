import 'package:dvote/dvote.dart';
import 'package:dvote/models/build/dart/client-store/recovery.pb.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/text-input.dart' as TextInput;
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/lib/util/normalize.dart';
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';
import 'package:vocdoni/views/recovery/recovery-success.dart';
import 'package:vocdoni/widgets/issues-button.dart';

class RecoveryVerificationArgs {
  final String accountName;
  final String date;
  final AccountRecovery recoveryModel;
  RecoveryVerificationArgs({
    @required this.accountName,
    @required this.date,
    @required this.recoveryModel,
  });
}

class RecoveryVerificationInput extends StatefulWidget {
  @override
  _RecoveryVerificationInputState createState() =>
      _RecoveryVerificationInputState();
}

class _RecoveryVerificationInputState extends State<RecoveryVerificationInput> {
  List<String> questionAnswers;
  List<int> questionIndexes;
  String name;
  AccountRecovery recovery;

  @override
  void initState() {
    questionAnswers = ["", ""];
    questionIndexes = [];
    super.initState();
    Globals.analytics.trackPage("RecoveryVerificationInput");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    final RecoveryVerificationArgs args =
        ModalRoute.of(context).settings.arguments;
    if (args == null) {
      Navigator.of(context).pop();
      logger.log("Invalid parameters");
      return;
    }
    name = args.accountName;
    recovery = args.recoveryModel;
    questionIndexes = recovery.questions.map((e) => int.parse(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
        appBar: TopNavigation(
          title: "",
          onBackButton: () => Navigator.pop(context, null),
        ),
        body: Builder(
          builder: (context) => Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Align(
                            alignment: Alignment.centerLeft,
                            child: extractBoldText(
                                    getText(context, "main.welcomeBackName")
                                        .replaceAll("NAME", name))
                                .withHPadding(spaceCard))
                        .withVPadding(paddingPage),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getText(context, "main.letsVerifyTheSecurityQuestions"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: fontWeightLight,
                          color: colorDescription,
                        ),
                      ).withHPadding(spaceCard),
                    ).withBottomPadding(30),
                    _buildBackupQuestion(0, context),
                    _buildBackupQuestion(1, context),
                  ],
                ).withVPadding(48),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Builder(
          builder: (context) => Row(
            children: [
              IssuesButton(),
              Spacer(),
              NavButton(
                  isDisabled:
                      questionAnswers.any((answer) => answer.length == 0),
                  style: NavButtonStyle.NEXT,
                  text: getText(context, "main.next"),
                  onTap: () {
                    _handleRecovery(context);
                  }),
            ],
          ).withPadding(spaceCard),
        ),
      ),
    );
  }

  _buildBackupQuestion(int position, BuildContext ctx) {
    if (questionIndexes.length <= position) return Container();
    final usedQuestions = questionIndexes.toList();
    usedQuestions.removeAt(position);
    return Column(
      children: [
        ListItem(
          mainText: (position + 1).toString() +
              ". " +
              getText(
                  ctx,
                  "main." +
                      AppConfig.backupQuestionTexts[
                          questionIndexes[position].toString()]),
          mainTextMultiline: 3,
          rightIcon: null,
        ),
        TextInput.TextInput(
          hintText: getText(context, "main.answer").toLowerCase(),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (answer) {
            setState(() {
              questionAnswers[position] = answer;
            });
          },
        ).withHPadding(paddingPage),
      ],
    ).withHPadding(8);
  }

  _handleRecovery(BuildContext context) async {
    if (questionAnswers.any((answer) => answer.length == 0)) {
      showMessage(getText(context, "main.pleaseAnswerBothRecoveryQuestions"),
          context: context, purpose: Purpose.WARNING);
      return "";
    }
    try {
      // Ask for pin
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PinPromptModal(
                    Globals.appState.currentAccount,
                    tryDecrypt: false,
                    accountName: name,
                  )));
      if (result == null) return "";
      if (result is InvalidPatternError) {
        showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
            context: context, purpose: Purpose.DANGER);
        Globals.analytics.trackPage("RecoveryVerificationFail");
        return Future.value();
      }

      showLoading(getText(context, "main.generatingIdentity"),
          context: context); //TODO test with wrong pin

      // Try to decrypt recovery key
      final pin = result;
      final answers = normalizeAnswers(questionAnswers.join());
      final decryptedMnemonic =
          await Symmetric.decryptStringAsync(recovery.key, pin + answers);
      if (decryptedMnemonic == null || decryptedMnemonic.length == 0) {
        Globals.analytics.trackPage("RecoveryVerificationFail");
        // if key not decrypted correctly
        showMessage(
            getText(context,
                "main.eitherThePINOrOneOfTheAnswersIsNotCorrectTryAgain"),
            context: context,
            purpose: Purpose.DANGER);
      } else {
        // Generate wallet. extract rootPublicKey to check for duplicates
        final wallet = EthereumWallet.fromMnemonic(decryptedMnemonic);
        final rootPublicKey = await wallet.publicKeyAsync();

        // Check for duplicates. If so, this is just a verification that the backup is valid. Display success view.
        final duplicate = Globals.accountPool?.value?.any((account) =>
                account.identity.value.keys.length > 0 &&
                pubKeysAreEqual(account.identity.value.keys[0].rootPublicKey,
                    rootPublicKey)) ??
            false;
        if (duplicate) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => RecoverySuccess()));
          return;
        }
        // Identity is not a duplicate, this is a real backup. Create identity
        final newAccount =
            await AccountModel.fromMnemonic(decryptedMnemonic, name, pin);
        newAccount.identity.value.backedUp = true;
        await Globals.accountPool.addAccount(newAccount);

        // Select new account
        final newIndex = Globals.accountPool.value.indexWhere((account) =>
            account.identity.hasValue &&
            pubKeysAreEqual(account.identity.value.identityId,
                newAccount.identity.value.identityId));
        Globals.appState.selectAccount(newIndex);
        Navigator.pushNamedAndRemoveUntil(context, "/home", (Route _) => false);
        return;
      }
    } catch (err) {
      logger.log("Could not recover identity: $err");
      Globals.analytics.trackPage("RecoveryVerificationFail");
      showMessage(
          getText(context,
              "main.eitherThePINOrOneOfTheAnswersIsNotCorrectTryAgain"),
          context: context,
          purpose: Purpose.DANGER);
      return Future.value();
    }
  }
}
