import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import '../models/model.dart';

class Server {
  Server({this.onError, this.onData});

  Uint8ListCallback? onData;
  DynamicCallback? onError;
  ServerSocket? server;
  bool running = false;
  List<Socket> sockets = [];

  start() async {
    runZoned(() async {
      server = await ServerSocket.bind('0.0.0.0', 4040);
      running = true;
      server!.listen(onRequest);

      Map<String, dynamic> messageMap = {
        'Username': 'Server',
        'Message': 'Server listening on port 4040',
      };

      String jsonString = jsonEncode(messageMap);

      Uint8List messageBytes = Uint8List.fromList(jsonString.codeUnits);

      onData!(messageBytes);

      // ignore: deprecated_member_use
    }, onError: (e) {
      onError!(e);
    });
  }

  stop() async {
    await server?.close();
    server = null;
    running = false;
  }

  broadCast(Map<String, dynamic> messageMap) {
    String jsonString = jsonEncode(messageMap);

    Uint8List messageBytes = Uint8List.fromList(jsonString.codeUnits);

    onData!(messageBytes);

    for (Socket socket in sockets) {
      socket.write('$jsonString\n');
    }
  }

  void write(Map<String, dynamic> messageMap) {
    String jsonString = jsonEncode(messageMap);

    Uint8List messageBytes = Uint8List.fromList(jsonString.codeUnits);

    onData!(messageBytes);
  }

  onRequest(Socket socket) {
    if (!sockets.contains(socket)) {
      sockets.add(socket);
    }
    socket.listen((Uint8List data) {
      onData!(data);
    });
  }
}
