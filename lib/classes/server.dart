import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

typedef StringCallback = void Function(String);
typedef DynamicCallback = void Function(dynamic);

class Server {
  Server({this.onError, this.onData});

  StringCallback? onData;
  DynamicCallback? onError;
  HttpServer? server;
  bool running = false;

  http.Client httpClient = http.Client();

  start() async {
    try {
      server = await HttpServer.bind('0.0.0.0', 4040);
      running = true;
      server!.listen(onRequest);

      Map<String, dynamic> messageMap = {
        'Username': 'Server',
        'Message': 'Server listening on port 4040',
      };

      String jsonString = jsonEncode(messageMap);

      onData!(jsonString);
    } catch (e) {
      onError!(e);
    }
  }

  stop() async {
    await server?.close();
    server = null;
    running = false;
  }

  void onRequest(HttpRequest request) async {
    if (request.method == 'POST') {
      await handlePost(request);
    } else {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${request.method}.')
        ..close();
    }
  }

  Future<void> handlePost(HttpRequest request) async {
    var jsonString = await utf8.decoder.bind(request).join();

    print('Received data on server: $jsonString');

    onData!(jsonString);
  }

  broadCast(Map<String, dynamic> messageMap, List<String> iplist) {
  iplist.forEach((ip) {
    response(messageMap, ip);
  });
}

  response(Map<String, dynamic> messageMap, hostname) async {
    try {
      String jsonString = jsonEncode(messageMap);
      final response = await httpClient.post(
        Uri.parse('http://$hostname:4040'),
        headers: {'Content-Type': 'application/json'},
        body: jsonString,
      );

      if (response.statusCode == 200) {
        print('Data sent successfully');
      } else {
        print('Error sending data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error writing to server: $e');
    }
  }

  void write(Map<String, dynamic> messageMap) {
    String jsonString = jsonEncode(messageMap);

    onData!(jsonString);
  }
}
