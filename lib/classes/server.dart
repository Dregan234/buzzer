import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
      onData!(
          Uint8List.fromList('Server listening on port 4040'.codeUnits));
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

  broadCast(String message) {
    onData!(Uint8List.fromList('Broadcasting : $message'.codeUnits));
    for (Socket socket in sockets) {
      socket.write('$message\n');
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