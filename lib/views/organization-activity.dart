import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';

class OrganizationActivity extends StatelessWidget {
  final Organization organization;

  OrganizationActivity({this.organization});

  @override
  Widget build(context) {
    return Scaffold(
        body: ListView.builder(
      itemCount: organization.newsFeed.length,
      itemBuilder: (BuildContext context, int index) {
        return ListItem(
          text: organization.newsFeed[index],
        );
      },
    ));
  }
}