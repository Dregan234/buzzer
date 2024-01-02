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
  // Convert the map to a JSON-formatted string
  String jsonString = jsonEncode(messageMap);

  // Convert the string to a Uint8List
  Uint8List messageBytes = Uint8List.fromList(jsonString.codeUnits);

  // Send the message to the onData callback
  onData!(messageBytes);

  // Broadcast the message to all connected sockets
  for (Socket socket in sockets) {
    socket.write(jsonString + '\n');
  }
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