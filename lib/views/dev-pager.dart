import "package:flutter/material.dart";
import 'package:vocdoni/widgets/pager/pager.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class DevPager extends StatelessWidget {
  @override
  Widget build(ctx) {

    List<Widget> pages = [
    Container(
      color: Colors.pink,
    ),
    Container(
      color: Colors.cyan,
      height: 200,
      width: 200,
    ),
    Container(
      color: Colors.deepPurple,
    ),
    Container(
      color: Colors.yellow,
      height:300
    ),
    Container(
      color: Colors.deepOrangeAccent,
    ),
  ];
   
    return Scaffold(
        appBar: TopNavigation(
          title: "Cards variants",
        ),
        body: new Pager(pages:pages, swipeEnabled: false,));
  }
}
