import 'package:convert/convert.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dvote/blockchain/ens.dart';
import 'package:dvote/dvote.dart';
import 'package:dvote/util/json-signature.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:flutter/material.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/logger.dart';
// import 'package:vocdoni/widgets/alerts.dart';
import 'package:dvote_common/widgets/baseCard.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:http/http.dart' as http;
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';

final _formKey = GlobalKey<FormState>();

final emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
final phoneRegExp = RegExp(r"^\+?[0-9\- ]+$");
final dateRegExp = RegExp(r"^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$");

class ActionRegisterPage extends StatelessWidget {
  final EntityMetadata_Action action;
  final String entityId;

  ActionRegisterPage(this.action, this.entityId);

  final nameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final birthDateCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  final nameNode = FocusNode();
  final lastNameNode = FocusNode();
  final birthDateNode = FocusNode();
  final emailNode = FocusNode();
  final phoneNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(title: getText(context, "main.register")),
      body: Builder(
          builder: (context) => ListView.builder(
                itemCount: 1,
                itemBuilder: (ctx, idx) => buildBody(ctx),
              )),
    );
  }

  Widget buildBody(BuildContext context) {
    return BaseCard(children: <Widget>[
      Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                getText(context, "main.personalDetails"),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
              ).withBottomPadding(8),
              Text(
                      getText(context,
                          "main.pleaseFillInTheFieldsBelowToCompleteYourRegistration"),
                      style: TextStyle(color: Colors.black45))
                  .withBottomPadding(20),
              TextFormField(
                validator: (value) => nameValidator(value, context),
                decoration: InputDecoration(
                    hintText: getText(context, "main.whatsYourName"),
                    hintStyle: TextStyle(color: Colors.black38)),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                focusNode: nameNode,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(lastNameNode),
                controller: nameCtrl,
              ).withBottomPadding(20),
              TextFormField(
                validator: (value) => nameValidator(value, context),
                decoration: InputDecoration(
                    hintText: getText(context, "main.whatsYourLastName"),
                    hintStyle: TextStyle(color: Colors.black38)),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                focusNode: lastNameNode,
                onFieldSubmitted: (_) => showBirthDatePicker(context),
                controller: lastNameCtrl,
              ).withBottomPadding(20),
              TextFormField(
                validator: (value) => dateValidator(value, context),
                decoration: InputDecoration(
                    hintText: getText(context, "main.whatIsYourBirthday"),
                    hintStyle: TextStyle(color: Colors.black38)),
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
                focusNode: birthDateNode,
                readOnly: true,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(emailNode),
                controller: birthDateCtrl,
                onTap: () => showBirthDatePicker(context),
              ).withBottomPadding(20),
              TextFormField(
                validator: (value) => emailValidator(value, context),
                decoration: InputDecoration(
                    hintText: getText(context, "main.whatsYourEmailAddress"),
                    hintStyle: TextStyle(color: Colors.black38)),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                focusNode: emailNode,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(phoneNode),
                controller: emailCtrl,
              ).withBottomPadding(20),
              TextFormField(
                validator: (value) => phoneValidator(value, context),
                decoration: InputDecoration(
                    hintText: getText(context, "main.phoneNumber"),
                    hintStyle: TextStyle(color: Colors.black38)),
                keyboardType: TextInputType.phone,
                focusNode: phoneNode,
                onFieldSubmitted: (_) => onSubmit(context),
                controller: phoneCtrl,
              ).withBottomPadding(20),
            ],
          )).withPadding(20.0),
      RaisedButton(
        onPressed: () => onSubmit(context),
        child: Text(getText(context, "main.register")),
      ).withBottomPadding(20).centered()
    ]);
  }

  String nameValidator(String value, BuildContext ctx) {
    if (value.isEmpty) return getText(ctx, "main.pleaseEnterYourName");
    return null;
  }

  String dateValidator(String value, BuildContext ctx) {
    if (value.isEmpty) return getText(ctx, "main.pleaseEnterYourBirthDate");

    if (dateRegExp.hasMatch(value)) return null;
    return getText(ctx, "main.pleaseSelectAValidDate");
  }

  String emailValidator(String value, BuildContext ctx) {
    if (value.isEmpty) return getText(ctx, "main.pleaseEnterYourEmail");

    if (emailRegExp.hasMatch(value)) return null;
    return getText(ctx, "main.pleaseEnterAValidEmail");
  }

  String phoneValidator(String value, BuildContext ctx) {
    if (value.isEmpty) return getText(ctx, "main.pleaseEnterAValidPhoneNumber");

    if (phoneRegExp.hasMatch(value)) return null;
    return getText(ctx, "main.pleaseEnterAValidPhoneNumber");
  }

  Future<void> showBirthDatePicker(BuildContext context) async {
    DateTime initial = DateTime(1975);
    if (birthDateCtrl.text.isNotEmpty) {
      final items = birthDateCtrl.text.split(r"-");
      if (items.length == 3) {
        final year = int.tryParse(items[0]);
        final month = int.tryParse(items[1]);
        final day = int.tryParse(items[2]);

        if (year != null && month != null && day != null) {
          initial = DateTime(year, month, day);
        }
      }
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1880),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget child) {
        return Theme(
          data: ThemeData.light(),
          child: child,
        );
      },
    );

    if (selectedDate is DateTime) {
      birthDateCtrl.text =
          "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
      FocusScope.of(context).requestFocus(emailNode);
    }
  }

  Future<void> onSubmit(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (!_formKey.currentState.validate()) return;

    final selectedAccount = Globals.appState.currentAccount;
    if (!(selectedAccount is AccountModel))
      throw Exception("The current account cannot be accessed");
    else if (!selectedAccount.identity.hasValue ||
        selectedAccount.identity.value.wallet.encryptedMnemonic.length < 1)
      throw Exception("The current identity doesn't have a key to sign");

    // final confirm = await showPrompt(
    //     "You are about to sign up. Do you want to continue?",
    //     context: context);
    // if (confirm != true) return;

    // SIGN

    var mnemonic = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PinPromptModal(selectedAccount)));
    if (mnemonic == null) {
      return;
    } else if (mnemonic is InvalidPatternError) {
      showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
          purpose: Purpose.DANGER, context: context);
    }

    // Derive the key for the entity

    final wallet = EthereumWallet.fromMnemonic(mnemonic,
        hdPath: selectedAccount.identity.value.wallet.hdPath,
        entityAddressHash: ensHashAddress(
            Uint8List.fromList(hex.decode(entityId.replaceFirst("0x", "")))));

    // Birth date in JSON format
    final dateItems = birthDateCtrl.text.split("-");
    if (dateItems.length != 3) {
      showMessage(getText(context, "main.pleaseSelectAValidDate"),
          purpose: Purpose.DANGER, context: context);
      return;
    }
    final dateOfBirth = DateTime.utc(int.tryParse(dateItems[0]),
        int.tryParse(dateItems[1]), int.tryParse(dateItems[2]), 12);

    final Map<String, dynamic> payload = {
      "request": {
        "method": "register",
        "actionKey": action.actionKey,
        "firstName": nameCtrl.text,
        "lastName": lastNameCtrl.text,
        "dateOfBirth": dateOfBirth.toIso8601String(),
        "email": emailCtrl.text,
        "phone": phoneCtrl.text,
        "entityId": entityId,
        "timestamp": DateTime.now().millisecondsSinceEpoch
      },
      "signature": "" // set right after
    };

    payload["signature"] = await JSONSignature.signJsonPayloadAsync(
        payload["request"], await wallet.privateKeyAsync);

    final Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    final loadingCtrl =
        showLoading(getText(context, "main.pleaseWait"), context: context);

    return http
        .post(action.url, body: jsonEncode(payload), headers: headers)
        .then((response) {
      if (response.statusCode != 200 || !(response.body is String))
        throw Exception("Invalid response");

      final body = jsonDecode(response.body);
      if (!(body is Map) || !(body["response"] is Map))
        throw Exception("Invalid response");
      else if (body["response"]["ok"] != true) {
        if (body["response"]["error"] is String)
          throw Exception(body["response"]["error"]);
        else
          throw Exception("The request failed");
      }

      // SUCCESS
      loadingCtrl.close();
      showMessage(getText(context, "main.yourRegistrationHasBeenHandled"),
          purpose: Purpose.GOOD, context: context);

      Future.delayed(Duration(seconds: 4))
          .then((_) => Navigator.of(context).pop());
    }).catchError((err) {
      loadingCtrl.close();
      showMessage(getText(context, "error.theRegistrationProcessFailed"),
          purpose: Purpose.DANGER, context: context);

      logger.log("Register error: $err");
      throw err;
    });
  }
}
