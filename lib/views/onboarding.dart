import "package:flutter/material.dart";

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vocdoni"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            Text("Onboarding"),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
