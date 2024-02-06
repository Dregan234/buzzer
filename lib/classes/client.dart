import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:Bonobuzzer/models/model.dart';

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

  Socket? socket;

  // Initialize the socket here
  Future<void> initSocket() async {
    socket = await Socket.connect(hostname, port);
    socket?.listen(
      onData,
      onError: onError,
      onDone: disconnect,
      cancelOnError: false,
    );
  }

  Future<void> connect() async {
    try {
      await initSocket();
      connected = true;
    } on Exception catch (exception) {
      onData!(Uint8List.fromList("Error : $exception".codeUnits));
    }
  }

  void write(Map<String, dynamic> messageMap) {
  try {
    String jsonString = jsonEncode(messageMap);
    socket?.write(jsonString);
  } catch (e) {
    print('Error writing to socket: $e');
  }
}

  void transmit(String message){
    socket?.write(message);
  }

  void disconnect() {
    socket?.destroy();
    connected = false;
  }
}
