import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/lib/util.dart';

class Summary extends StatefulWidget {
  final String text;
  final int maxLines;

  Summary({this.text, this.maxLines});

  @override
  _SummaryState createState() => _SummaryState();
}

class _SummaryState extends State<Summary> with TickerProviderStateMixin {
  bool collapsed = true;
  @override
  Widget build(context) {
    return AnimatedSize(
        alignment: Alignment.topLeft,
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 300),
        vsync: this,
        child: InkWell(
            onTap: () => setState(() {
                  devPrint("is collapsed" + collapsed.toString());
                  collapsed = !collapsed;
                }),
            child: Container(
                padding: new EdgeInsets.all(paddingPage),
                child: Text(
                  widget.text,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  maxLines: collapsed ? widget.maxLines : 100,
                  style: TextStyle(
                      fontSize: 16,
                      color: colorDescription,
                      fontWeight: fontWeightLight),
                ))));
  }
}
