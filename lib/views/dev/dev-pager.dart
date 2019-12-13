import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/bubble.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/pager/pager.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class DevPager extends StatefulWidget {
  @override
  _DevPagerState createState() => _DevPagerState();
}

class _DevPagerState extends State<DevPager> {
  int _optionSelected1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _optionSelected1 = null;
  }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListItem(
              mainText: "Do you like cheese?",
              secondaryText:
                  "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source.Love encompasses a range of strong and positive emotional and mental states, from the most sublime virtue or good habit, the deepest interpersonal affection ...",
              secondaryTextMultiline: 100,
              rightIcon: null,
            ),
            Bubble(
              selected: _optionSelected1 == 0,
              onTap: () {
                setState(() {
                  _optionSelected1 = 0;
                });
              },
              child: Text(
                "Option two",
                overflow: TextOverflow.ellipsis,
                maxLines: 100,
                style: TextStyle(
                    fontSize: fontSizeSecondary,
                    fontWeight: fontWeightRegular,
                    color: Colors.white),
              ),
            ),
            Bubble(
              selected: _optionSelected1 == 1,
              onTap: () {
                setState(() {
                  _optionSelected1 = 1;
                });
              },
              child: Text(
                "Love encompasses a range of strong and positive emotional and mental states, from the most sublime virtue or good habit, the deepest interpersonal affection ...",
                overflow: TextOverflow.ellipsis,
                maxLines: 100,
                style: TextStyle(
                    fontSize: fontSizeSecondary,
                    fontWeight: fontWeightRegular,
                    color: Colors.white),
              ),
            ),
            Bubble(
              selected: _optionSelected1 == 2,
              onTap: () {
                setState(() {
                  _optionSelected1 = 2;
                });
              },
              child: Text(
                "Love encompasses a range of strong and positive emotional and mental states, from the most sublime virtue or good habit, the deepest interpersonal affection ...Love encompasses a range of strong and positive emotional and mental states, from the most sublime virtue or good habit, the deepest interpersonal affection ...",
                overflow: TextOverflow.ellipsis,
                maxLines: 5,
                style: TextStyle(
                    fontSize: fontSizeSecondary,
                    fontWeight: fontWeightRegular,
                    color: Colors.white),
              ),
            ),
            
          ],
        ),
        //color: Colors.red,
      ),
      Container(color: Colors.yellow, height: 300),
      Container(
        color: Colors.deepOrangeAccent,
      ),
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
      Container(color: Colors.yellow, height: 300),
      Container(
        color: Colors.deepOrangeAccent,
      ),
    ];

    return Scaffold(
        appBar: TopNavigation(
          title: "Cards variants",
        ),
        body: new Pager(
          pages: pages,
          swipeEnabled: true,
          dotTapEnabled: true,
        ));
  }
}
