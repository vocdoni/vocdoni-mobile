import 'package:flutter/material.dart';

import "views/welcome.dart";
import "views/onboarding.dart";

void main() {
  runApp(VocdoniApp());
}

class VocdoniApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Vocdoni',
        routes: {
          "/": (context) => WelcomeScreen(),
          "/test1": (context) => WelcomeScreen(),
          "/test2": (context) => OnboardingScreen(),
          "/test3": (context) => WelcomeScreen(),
          "/test4": (context) => WelcomeScreen()
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ));
  }
}
