import 'package:flutter/material.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:native_widgets/native_widgets.dart';

class CardLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseCard(children: <Widget>[
      Center(
        child: Text("Loading..."),
      )
    ]);
  }
}
