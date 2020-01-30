import 'package:flutter/material.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'loading-spinner.dart';

class CardLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseCard(children: <Widget>[
      Center(
        child: Column(children: [
          Text("Loading..."),
          LoadingSpinner(),
        ]),
      )
    ]);
  }
}
