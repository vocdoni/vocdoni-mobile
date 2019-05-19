import 'dart:async';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/modals/select-identity.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/app-links.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/toast.dart';
import '../lang/index.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /////////////////////////////////////////////////////////////////////////////
  // DEEP LINKS / UNIVERSAL LINKS
  /////////////////////////////////////////////////////////////////////////////

  StreamSubscription<Uri> linkChangeStream;

  @override
  void initState() {
    try {
      // Handle the initial link
      getInitialUri()
          .then((initialUri) => handleLink(initialUri))
          .catchError((err) => handleIncomingLinkError(err));

      // Listen to link changes
      linkChangeStream = getUriLinksStream()
          .listen((uri) => handleLink(uri), onError: handleIncomingLinkError);
    } catch (err) {
      showAlert(
          title: Lang.of(context).get("Error"),
          text: Lang.of(context)
              .get("The link you followed appears to be invalid"),
          context: context);
    }

    super.initState();
  }

  handleLink(Uri givenUri) {
    handleIncomingLink(givenUri, homePageScaffoldKey.currentContext)
        .then((String result) => handleLinkSuccess(result))
        .catchError(handleIncomingLinkError);
  }

  handleLinkSuccess(String text) {
    if (text == null || !(text is String)) return;

    showSuccessMessage(text, global: true);
  }

  handleIncomingLinkError(err) {
    if (err == "Already subscribed") {
      return showMessage(
          Lang.of(context)
              .get("You are already subscribed to this organization"),
          global: true);
    }
    print(err);
    showAlert(
        title: Lang.of(homePageScaffoldKey.currentContext).get("Error"),
        text: Lang.of(homePageScaffoldKey.currentContext)
            .get("There was a problem handling the link provided"),
        context: homePageScaffoldKey.currentContext);
  }

  @override
  void dispose() {
    if (linkChangeStream != null) linkChangeStream.cancel();
    super.dispose();
  }

  /////////////////////////////////////////////////////////////////////////////
  // MAIN
  /////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(context) {
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                return Scaffold(
                  key: homePageScaffoldKey,
                  appBar: AppBar(
                    title: Text("Vocdoni"),
                    backgroundColor: mainBackgroundColor,
                  ),
                  drawer: homeDrawer(ctx, appState.data, identities.data),
                  body: homeBody(ctx, appState.data, identities.data),
                  bottomNavigationBar: BottomNavigation(),
                );
              });
        });
  }

  homeDrawer(
      BuildContext context, AppState appState, List<Identity> identities) {
    String identAlias = "";
    String identAddress = "";
    List<ListTile> organizationTiles = [];
    if (appState?.selectedIdentity is int) {
      identAlias = identities[appState.selectedIdentity].alias;
      identAddress = identities[appState.selectedIdentity].address;

      if (identities[appState.selectedIdentity].organizations?.length > 0) {
        final orgs = identities[appState.selectedIdentity].organizations;
        organizationTiles = orgs.asMap().keys.map((idx) {
          return ListTile(
              leading: Icon(Icons.home),
              title: Text(orgs[idx].name ?? ""),
              onTap: () => selectOrganization(idx, context),
              trailing: InkWell(
                child: Icon(Icons.remove_circle_outline),
                onTap: () => promptRemoveOrganization(idx),
              ));
        }).toList();
      }
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(identAlias,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1,
                    )),
                Text(
                  identAddress,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: mainBackgroundColor,
            ),
          ),
          (identities != null && identities.length > 1)
              ? ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Switch Identity'),
                  onTap: () => selectIdentity(context),
                )
              : Container(),
          ...organizationTiles,
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

  homeBody(BuildContext context, AppState appState, List<Identity> identities) {
    Organization currentOrg;
    if (identities != null &&
        identities.length > 0 &&
        identities[appState.selectedIdentity].organizations?.length > 0) {
      currentOrg = identities[appState.selectedIdentity]
          .organizations[appState.selectedOrganization];
    }
    return Container(
      child: Column(
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(children: [
                  Text("HOME SCREEN"),
                  SizedBox(height: 20),
                  Text("Available Identities:"),
                  (identities == null)
                      ? Text("(empty?)")
                      : Text(identities.map((idt) => idt.alias).join(", ")),
                  SizedBox(height: 20),
                  Text("CURRENT IDENTITY:"),
                  (appState?.selectedIdentity is int)
                      ? Text(identities[appState.selectedIdentity].alias)
                      : Text(""),
                  SizedBox(height: 20),
                  Text("CURRENT ORG:"),
                  currentOrg != null
                      ? Column(children: [
                          Text(currentOrg.name),
                          //Text(currentOrg.description[currentOrg.languages[0]] ??"-"),
                          //Text(currentOrg.languages.join(", ")),
                          //Text(currentOrg.avatar),
                        ])
                      : Text("NO ORGS YET")
                ]),
              ),
            ),
          ]),
          Row(
            children: <Widget>[
              Expanded(
                child: FlatButton(
                  color: Colors.blue[100],
                  child: Padding(
                      child:
                          currentOrg != null && currentOrg.actions?.length > 0
                              ? Text(currentOrg.actions[0]["name"]
                                  [currentOrg.languages[0]])
                              : Text("(NO ACTIONS)"),
                      padding: EdgeInsets.all(24)),
                  onPressed: () {
                    if (currentOrg == null ||
                        currentOrg.actions?.length < 1 &&
                            currentOrg.actions[0]["url"] == null) return;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WebAction(
                                  url: currentOrg.actions[0]["url"],
                                )));
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  selectIdentity(BuildContext ctx) async {
    Navigator.pop(ctx);
    final result = await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (ctx) => SelectIdentityModal()),
    );

    if (result is int) {
      appStateBloc.selectIdentity(result);

      showMessage(
          Lang.of(ctx).get("Using: ") + identitiesBloc.current[result].alias,
          global: true);
    }
  }

  selectOrganization(int idx, BuildContext ctx) async {
    if (idx is int) {
      appStateBloc.selectOrganization(idx);

      showMessage(
          Lang.of(ctx).get("Using: ") +
              identitiesBloc.current[0].organizations[idx].name,
          global: true);
      Navigator.of(context).pop();
    }
  }

  promptRemoveOrganization(int idx) async {
    // TODO:
  }
}
