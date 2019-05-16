import 'dart:async';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/modals/select-identity.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/app-links.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/toast.dart';
// import 'package:vocdoni/widgets/toast.dart';
import '../lang/index.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Global scaffold key for snackbars
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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
    handleIncomingLink(givenUri, _scaffoldKey.currentContext)
        .then((String result) => handleLinkSuccess(result))
        .catchError(handleIncomingLinkError);
  }

  handleLinkSuccess(String text) {
    if (text == null || !(text is String)) return;

    // Try to merge with showSuccessMessage()
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: successColor,
      content: Text(text),
    ));
  }

  handleIncomingLinkError(err) {
    showAlert(
        title: Lang.of(_scaffoldKey.currentContext).get("Error"),
        text: Lang.of(_scaffoldKey.currentContext)
            .get("There was a problem handling the link provided"),
        context: _scaffoldKey.currentContext);
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
                  key: _scaffoldKey,
                  appBar: AppBar(
                    title: Text("Vocdoni"),
                    backgroundColor: mainBackgroundColor,
                  ),
                  drawer: homeDrawer(ctx, appState.data, identities.data),
                  body: homeBody(ctx, appState.data, identities.data),
                );
              });
        });
  }

  homeDrawer(
      BuildContext context, AppState appState, List<Identity> identities) {
    final String identAlias = (appState?.selectedIdentity is int)
        ? identities[appState.selectedIdentity].alias
        : "";
    final String identAddress = (appState?.selectedIdentity is int)
        ? identities[appState.selectedIdentity].address
        : "";

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
          ListTile(
              leading: Icon(Icons.home),
              title: Text('Organization 1 (TODO)'),
              onTap: () => {appStateBloc.selectOrganization(0)},
              trailing: InkWell(
                child: Icon(Icons.remove_circle_outline),
                onTap: () => print("CLICK"),
              )),
          ListTile(
              leading: Icon(Icons.home),
              title: Text('Organization 2 (TODO)'),
              onTap: () => {appStateBloc.selectOrganization(1)},
              trailing: InkWell(
                child: Icon(Icons.remove_circle_outline),
                onTap: () => print("CLICK"),
              )),
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
                  Text("CURRENT ORG: ${appState?.selectedOrganization}"),
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
                      child: Text("LAUNCH ORG ACTION"),
                      padding: EdgeInsets.all(24)),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => WebAction()));
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

      // TODO: Needs rearranging the Scaffold hierarchy
      // Scaffold.of(ctx)
      //   ..removeCurrentSnackBar()
      //   ..showSnackBar(SnackBar(content: Text("$result")));
    }
  }
}
