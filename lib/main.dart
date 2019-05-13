import 'package:flutter/material.dart';
import './util/singletons.dart';

void main() {
  runApp(VocdoniApp());
}

class VocdoniApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocdoni',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Vocdoni"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              InkWell(
                  child: Text("Web Runtime trigger"),
                  onTap: () => handleRuntimeCall()),
              Spacer(),
              InkWell(child: Text("Set Entity 1"), onTap: () => incIdent()),
              InkWell(child: Text("Set Org 1"), onTap: () => incOrg()),
              Spacer(),
              StreamBuilder(
                  stream: appStateBloc.stream,
                  builder: (BuildContext context, AsyncSnapshot<AppState> snapshot) {
                    final state = snapshot.data;
                    if (state == null) return Text("");
                    return Text("Entity Idx: ${state.selectedIdentity}");
                  }),
              StreamBuilder(
                  stream: appStateBloc.stream,
                  builder: (BuildContext context, AsyncSnapshot<AppState> snapshot) {
                    final state = snapshot.data;
                    if (state == null) return Text("");
                    return Text("Org Idx: ${state.selectedOrganization}");
                  }),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  handleRuntimeCall() {
    webRuntime
        .call("generateMnemonic()")
        .then((mnemonic) {
          print("MNEMONIC: $mnemonic");
          return webRuntime.call("mnemonicToAddress(\"$mnemonic\")");
        })
        .then((address) => print("ADDR: $address"))
        .catchError((err) => print("ERR: " + err.toString()));
  }

  incIdent() {
    appStateBloc.selectIdentity(appStateBloc.current.selectedIdentity + 1);
  }

  incOrg() {
    appStateBloc
        .selectOrganization(appStateBloc.current.selectedOrganization + 1);
  }
}
