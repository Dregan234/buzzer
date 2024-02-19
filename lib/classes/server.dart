import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

typedef Uint8ListCallback = void Function(Uint8List);
typedef DynamicCallback = void Function(dynamic);

class Server {
  Server({this.onError, this.onData});

  Uint8ListCallback? onData;
  DynamicCallback? onError;
  ServerSocket? server;
  bool running = false;
  bool svgTransmissionInProgress = false;
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

  response(Map<String, dynamic> messageMap) {
    String jsonString = jsonEncode(messageMap);

    for (Socket socket in sockets) {
      socket.write('$jsonString\n');
    }
  }

  void write(Map<String, dynamic> messageMap) {
    String jsonString = jsonEncode(messageMap);

    Uint8List messageBytes = Uint8List.fromList(jsonString.codeUnits);

    onData!(messageBytes);
  }

  void onRequest(Socket socket) {
    if (!sockets.contains(socket)) {
      sockets.add(socket);
    }
    String clientIP = socket.remoteAddress.address;
    socket.listen((Uint8List data) {
      if (svgTransmissionInProgress) {
        Map<String, dynamic> messageMap = {
          'Status': 'transmitclosed',
          'IP': clientIP,
        };
        String jsonString = jsonEncode(messageMap);
        Uint8List messageBytes = Uint8List.fromList(jsonString.codeUnits);
        socket.write(messageBytes);
      } else {
        Map<String, dynamic> messageMap = {
          'Status': 'transmitopen',
          'IP': clientIP,
        };
        String jsonString = jsonEncode(messageMap);
        Uint8List messageBytes = Uint8List.fromList(jsonString.codeUnits);
        socket.write(messageBytes);
      }
      return;
    });
  }

  void startSVGTransmission() {
    svgTransmissionInProgress = true;
  }

  void endSVGTransmission() {
    svgTransmissionInProgress = false;
  }
}
