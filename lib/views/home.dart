import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
// import 'dart:convert';
import '../lang/index.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Vocdoni"),
          backgroundColor: mainBackgroundColor,
        ),
        drawer: HomeDrawer(context),
        body: HomeBody(context));
  }

  HomeDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Identity',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1,
                    )),
                Text('0x12341234',
                    style: TextStyle(
                      color: Colors.white,
                    )),
              ],
            ),
            decoration: BoxDecoration(
              color: mainBackgroundColor,
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Switch Identity'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Organization 1'),
            onTap: () => {},
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Organization 2'),
            onTap: () => {},
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, "/welcome");
            },
          ),
        ],
      ),
    );
  }

  HomeBody(BuildContext context) {
    return Center(
      child: StreamBuilder(
          stream: identitiesBloc.stream,
          builder:
              (BuildContext context, AsyncSnapshot<List<Identity>> identities) {
            return StreamBuilder(
                stream: appStateBloc.stream,
                builder:
                    (BuildContext context, AsyncSnapshot<AppState> appState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("HOME SCREEN"),
                      Text("Available Identities:"),
                      (identities.data == null)
                          ? Text("(empty?)")
                          : Text(identities.data
                              .map((idt) => idt.alias)
                              .join(", ")),
                      Text("\n\nCURRENT ID: ${appState.data.selectedIdentity}"),
                      Text(identities
                          .data[appState.data.selectedIdentity].alias),
                      Text("\nCURRENT ORG: ${appState.data.selectedOrganization}")
                    ],
                  );
                });
          }),
    );
  }
}
