import 'dart:io';
import 'dart:typed_data';

import '../models/model.dart';

class Client {
  Client({
    this.onError,
    this.onData,
    required this.hostname,
    required this.port,
  });

  String hostname;
  int port;
  Uint8ListCallback? onData;
  DynamicCallback? onError;
  bool connected = false;

  late Socket socket;

  Future<void> connect() async {
    try {
      socket = await Socket.connect(hostname, port);
      socket.listen(
        onData,
        onError: onError,
        onDone: disconnect,
        cancelOnError: false,
      );
      connected = true;
    } on Exception catch (exception) {
      onData!(Uint8List.fromList("Error : $exception".codeUnits));
    }
  }

  void write(String message) {
    socket.write('$message\n');
  }

  void disconnect() {
    socket.destroy();
    connected = false;
  }
}