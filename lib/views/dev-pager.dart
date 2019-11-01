import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/listItem.dart';
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListItem(
              mainText: "Do you like cheese?",
              secondaryText:
                  "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source.",
              secondaryTextMultiline: 100,
              rightIcon: null,
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(paddingPage, 0, paddingPage, 0),
                child: ChoiceChip(
                  selected: true,
                  backgroundColor: colorLightGuide,
                  selectedColor: colorBlue,
                  padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
                  label: Text(
                    "Option one",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: TextStyle(
                        fontSize: fontSizeSecondary,
                        fontWeight: fontWeightRegular,
                        color: Colors.white),
                  ),
                )),
            Padding(
                padding: EdgeInsets.fromLTRB(paddingPage, 0, paddingPage, 0),
                child: ChoiceChip(
                  selected: false,
                  backgroundColor: colorLightGuide,
                  selectedColor: colorBlue,
                  padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
                  label: Text(
                    "Option one",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: TextStyle(
                        fontSize: fontSizeSecondary,
                        fontWeight: fontWeightRegular,
                        color: Colors.white),
                  ),
                ))
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
