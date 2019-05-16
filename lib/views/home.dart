import 'dart:async';
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/modals/select-identity.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/app-links.dart';
import 'package:vocdoni/widgets/alerts.dart';
// import 'package:vocdoni/widgets/toast.dart';
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
          .then((initialLink) => handleIncomingLink(initialLink, context))
          .catchError((err) => handleIncomingLinkError(err));

      // Listen to link changes
      linkChangeStream = getUriLinksStream().listen(
          (uri) => handleIncomingLink(uri, context).catchError(handleIncomingLinkError),
          onError: handleIncomingLinkError);
    } catch (err) {
      showAlert(
          title: Lang.of(context).get("Error"),
          text: Lang.of(context)
              .get("The link you followed appears to be invalid"),
          context: context);
    }

    super.initState();
  }

  handleIncomingLinkError(err) {
    showAlert(
        title: Lang.of(context).get("Error"),
        text:
            Lang.of(context).get("The link you followed appears to be invalid"),
        context: context);
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
                Text(identAddress,
                    style: TextStyle(
                      color: Colors.white,
                    )),
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
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Organization 2 (TODO)'),
            onTap: () => {appStateBloc.selectOrganization(1)},
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

  homeBody(BuildContext context, AppState appState, List<Identity> identities) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("HOME SCREEN"),
        Text("Available Identities:"),
        (identities == null)
            ? Text("(empty?)")
            : Text(identities.map((idt) => idt.alias).join(", ")),
        Text("CURRENT ID: ${appState?.selectedIdentity}"),
        (appState?.selectedIdentity is int)
            ? Text(identities[appState.selectedIdentity].alias)
            : Text(""),
        Text("\nCURRENT ORG: ${appState?.selectedOrganization}"),
        FlatButton(
          color: mainBackgroundColor,
          textColor: mainTextColor,
          padding: EdgeInsets.all(16),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => WebAction()));
          },
          child: Text(Lang.of(context).get("Org action")),
        )
      ],
    ));
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
