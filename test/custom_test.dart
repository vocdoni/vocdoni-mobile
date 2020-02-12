import "dart:io";

import 'dart:typed_data';

const GATEWAY_URI = 'wss://gwdev1.vocdoni.net/dvote';
// const GATEWAY_URI = 'ws://127.0.0.1:9090/dvote';

void main() async {
  var socket = await WebSocket.connect(GATEWAY_URI);

  final req =
      '{"id":"ZJ/smo0nYFektsNwaVLYZQ==","request":{"method":"fetchFile","uri":"ipfs://QmZuUJATU8N8yFJuhBjt9N8RvxB7nU1YSvokJ7yoKzGGgy","timestamp":1581525774},"signature":""}';

  socket.listen((res) => gotMessage(Uint8List.fromList(res)));

  for (int i = 0; i < 500; i++) {
    socket.add(req);
  }

  await Future.delayed(Duration(seconds: 5));
  socket.close();
}

void gotMessage(Uint8List data) {
  final txt = String.fromCharCodes(data);
  print("[${DateTime.now()}] Got ${txt.length} bytes");
}
