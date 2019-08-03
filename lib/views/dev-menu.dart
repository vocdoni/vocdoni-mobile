import "package:flutter/material.dart";
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/util/dev/populate.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/views/dev-ui-elements.dart';

class DevMenu extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "Post",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(
                text: "Add fake organizations",
                onTap: () async {
                  // TODO: REMOVE
                  try {
                    await populateSampleData();
                    showMessage("Completed", context: ctx);
                  } catch (err) {
                    showErrorMessage(err?.message ?? err, context: ctx);
                  }
                }),
            ListItem(
              text: "See UI elements",
              onTap: () {
                Navigator.pushNamed(ctx, "/dev/ui-elements");
              },
            )
          ],
        ));
  }
}
