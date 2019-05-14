import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';

// TODO: LOCALIZE

final pages = [
  new PageViewModel(
      mainBackgroundColor,
      'assets/media/mountain.png',
      'Self sovereign identity',
      'An identity that you create and you own',
      'assets/media/plane.png'),
  new PageViewModel(
      altBackgroundColor,
      'assets/media/world.png',
      'Anonymous voting',
      'Speak your voice with the confidence that your opinion is safe',
      'assets/media/calendar.png'),
  new PageViewModel(
      alt2BackgroundColor,
      'assets/media/home.png',
      'End to end verifiable',
      'Participate on elections that you and anyone can verify',
      'assets/media/house.png',
      "Get Started",
      "/welcome/identity"),
];

class Page extends StatelessWidget {
  final PageViewModel viewModel;
  final double percentVisible;

  Page({
    this.viewModel,
    this.percentVisible = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return new Container(
        width: double.infinity,
        color: viewModel.color,
        child: new Opacity(
          opacity: percentVisible,
          child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                new Transform(
                  transform: new Matrix4.translationValues(
                      0.0, 50.0 * (1.0 - percentVisible), 0.0),
                  child: new Padding(
                    padding: new EdgeInsets.only(bottom: 25.0),
                    child: new Image.asset(viewModel.heroAssetPath,
                        width: 200.0, height: 200.0),
                  ),
                ),
                new Transform(
                  transform: new Matrix4.translationValues(
                      0.0, 30.0 * (1.0 - percentVisible), 0.0),
                  child: new Padding(
                    padding: new EdgeInsets.all(10),
                    child: new Text(
                      viewModel.title,
                      style: new TextStyle(
                        color: Colors.white,
                        fontSize: 30.0,
                      ),
                    ),
                  ),
                ),
                new Transform(
                  transform: new Matrix4.translationValues(
                      0.0, 30.0 * (1.0 - percentVisible), 0.0),
                  child: new Padding(
                    padding: new EdgeInsets.only(
                        bottom: 20.0, left: 10.0, right: 10.0),
                    child: new Text(
                      viewModel.body,
                      textAlign: TextAlign.center,
                      style: new TextStyle(
                        color: Colors.white,
                        fontSize: 17.0,
                      ),
                    ),
                  ),
                ),
                viewModel.callToAction == null
                    ? Container()
                    : new Transform(
                        transform: new Matrix4.translationValues(
                            0.0, 30.0 * (1.0 - percentVisible), 0.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 90,
                          child: Padding(
                            padding:
                                EdgeInsets.only(left: 5, right: 5, top: 35),
                            child: FlatButton(
                              color: Colors.white,
                              textColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 64),
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, viewModel.callToActionRoute);
                              },
                              child: Text(viewModel.callToAction,
                                  style: TextStyle(fontSize: 15.0)),
                            ),
                          ),
                        ),
                      )
              ]),
        ));
  }
}

class PageViewModel {
  final Color color;
  final String heroAssetPath;
  final String title;
  final String body;
  final String iconAssetPath;
  final String callToAction;
  final String callToActionRoute;

  PageViewModel(
      this.color, this.heroAssetPath, this.title, this.body, this.iconAssetPath,
      [this.callToAction, this.callToActionRoute]);
}
