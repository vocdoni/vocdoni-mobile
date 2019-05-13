import 'package:flutter/material.dart';
import './util/web-runtime.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
                child: Text("Press me"),
                onTap: () {
                  runtime
                      .call("generateMnemonic()")
                      .then((mnemonic) {
                        print("MNEMONIC: $mnemonic");
                        return runtime.call("mnemonicToAddress(\"$mnemonic\")");
                      })
                      .then((address) => print("ADDR: $address"))
                      .catchError((err) => print("ERR: " + err.toString()));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

WebRuntime runtime = new WebRuntime();
