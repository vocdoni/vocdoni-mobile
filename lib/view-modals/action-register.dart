import 'dart:convert';
import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/util.dart';
// import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/widgets/baseCard.dart';
// import 'package:vocdoni/widgets/loading-spinner.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:http/http.dart' as http;

final _formKey = GlobalKey<FormState>();

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
      appBar: TopNavigation(title: Lang.of(context).get("Register")),
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
            children: <Widget>[
              TextFormField(
                validator: (value) => nameValidator(value),
                decoration: InputDecoration(
                    hintText: "What's your name?",
                    hintStyle: TextStyle(color: Colors.black38)),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                focusNode: nameNode,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(lastNameNode),
                controller: nameCtrl,
              ).withBottomPadding(20),
              TextFormField(
                validator: (value) => nameValidator(value),
                decoration: InputDecoration(
                    hintText: "What's your last name?",
                    hintStyle: TextStyle(color: Colors.black38)),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                focusNode: lastNameNode,
                onFieldSubmitted: (_) => showBirthDatePicker(context),
                controller: lastNameCtrl,
              ).withBottomPadding(20),
              TextFormField(
                validator: (value) => dateValidator(value),
                decoration: InputDecoration(
                    hintText: "What is your birthday?",
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
                validator: (value) => emailValidator(value),
                decoration: InputDecoration(
                    hintText: "What's your Email?",
                    hintStyle: TextStyle(color: Colors.black38)),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                focusNode: emailNode,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(phoneNode),
                controller: emailCtrl,
              ).withBottomPadding(20),
              TextFormField(
                validator: (value) => phoneValidator(value),
                decoration: InputDecoration(
                    hintText: "Phone number",
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
        child: Text('Register'),
      ).withBottomPadding(20).centered()
    ]);
  }

  String nameValidator(String value) {
    if (value.isEmpty) return 'Please complete this field';
    return null;
  }

  String dateValidator(String value) {
    if (value.isEmpty) return 'Please complete your birth date';

    final dateRegExp = RegExp(r"^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$");

    if (dateRegExp.hasMatch(value)) return null;
    return "Please, enter a valid date";
  }

  String emailValidator(String value) {
    if (value.isEmpty) return 'Please enter your email';

    final emailRegExp = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

    if (emailRegExp.hasMatch(value)) return null;
    return "Please, enter a valid email";
  }

  String phoneValidator(String value) {
    if (value.isEmpty) return 'Please enter a valid phone number';

    final phoneRegExp = RegExp(r"^\+?[0-9\- ]+$");

    if (phoneRegExp.hasMatch(value)) return null;
    return "Please, enter a valid phone number";
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

    final selectedAccount = globalAppState.currentAccount;
    if (!(selectedAccount is AccountModel))
      throw Exception("The current account cannot be accessed");
    else if (!selectedAccount.identity.hasValue ||
        selectedAccount.identity.value.keys.length < 1)
      throw Exception("The current identity doesn't have a key to sign");

    // final confirm = await showPrompt(
    //     "You are about to sign up. Do you want to continue?",
    //     context: context);
    // if (confirm != true) return;

    // SIGN
    final identity = selectedAccount.identity.value;
    final encryptedPrivateKey = identity.keys[0].encryptedPrivateKey;

    var patternStr = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PatternPromptModal(selectedAccount)));
    if (patternStr == null || patternStr is InvalidPatternError) {
      return;
    }

    String privateKey = await decryptString(encryptedPrivateKey, patternStr);

    final fullName = nameCtrl.text + " " + lastNameCtrl.text;
    final signature =
        await signString(jsonEncode({"fullName": fullName}), privateKey);
    privateKey = null;

    final Map<String, dynamic> payload = {
      "request": {
        "method": "register",
        "name": nameCtrl.text,
        "lastName": lastNameCtrl.text,
        "birth": birthDateCtrl.text,
        "email": emailCtrl.text,
        "phone": phoneCtrl.text,
        "entityId": entityId
      },
      "signature": signature
    };

    final Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    final loadingCtrl = showLoading("Please, wait...", context: context);

    return http
        .post(action.url, body: jsonEncode(payload), headers: headers)
        .then((response) {
      if (response.statusCode != 200 || !(response.body is String))
        throw Exception("Invalid response");

      final body = jsonDecode(response.body);
      if (!(body is Map))
        throw Exception("Invalid response");
      else if (body["ok"] != true) {
        if (body["error"] is String)
          throw Exception(body["error"]);
        else
          throw Exception("The request failed");
      }
      // SUCCESS
      loadingCtrl.close();
      showMessage(Lang.of(context).get("Your registration has been handled"),
          purpose: Purpose.GOOD, context: context);

      Navigator.of(context).pop();
    }).catchError((err) {
      loadingCtrl.close();
      showMessage(Lang.of(context).get("The registration process failed"),
          purpose: Purpose.DANGER, context: context);

      devPrint("Register error: $err");
      throw err;
    });
  }
}
