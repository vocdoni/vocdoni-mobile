import 'package:flutter/material.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'loading-spinner.dart';

class CardLoading extends StatelessWidget {
  final String message;
  CardLoading([this.message]);

  @override
  Widget build(BuildContext context) {
    return BaseCard(children: <Widget>[
      Center(
        child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Column(children: [
              Text(message ?? "Loading..."),
              SizedBox(height: 15.0),
              LoadingSpinner(),
            ])),
      )
    ]);
  }
}
