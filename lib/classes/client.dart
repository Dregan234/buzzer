import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

typedef StringCallback = void Function(String);
typedef DynamicCallback = void Function(dynamic);

class Client {
  Client({
    this.onError,
    this.onData,
    required this.hostname,
    required this.port,
  });

  String hostname;
  int port;
  StringCallback? onData;
  DynamicCallback? onError;
  bool connected = false;
  http.Client httpClient = http.Client();
  HttpServer? server;
  bool running = false;

  start() async {
    try {
      server = await HttpServer.bind('0.0.0.0', 4040);
      running = true;
      server!.listen(onRequest);

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
    try {
      var jsonString = await utf8.decoder.bind(request).join();
      var data = jsonDecode(jsonString);

      print('Received data on server: $data');

      request.response
        ..statusCode = HttpStatus.ok
        ..write('Received data: $data')
        ..close();

    onData!(jsonString);

    } catch (e) {
      print('Error handling POST request: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Error handling POST request: $e')
        ..close();
    }
  }

  Future<void> connect() async {
    try {
      connected = true;
      start();
    } on Exception catch (exception) {
      onData!("Error : $exception".codeUnits as String);
    }
  }

  void write(Map<String, dynamic> messageMap) async {
    try {
      String jsonString = jsonEncode(messageMap);
      final response = await httpClient.post(
        Uri.parse('http://$hostname:$port'),
        headers: {'Content-Type': 'application/json'},
        body: jsonString,
      );

      if (response.statusCode == 200) {
        // Successfully sent data
        print('Data sent successfully');
      } else {
        // Handle error
        print('Error sending data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error writing to server: $e');
    }
  }

  void transmit(String message) async {
    // Example: Sending a simple message
    final response = await httpClient.post(
      Uri.parse('http://$hostname:$port'),
      headers: {'Content-Type': 'text/plain'},
      body: message,
    );

    if (response.statusCode == 200) {
      // Successfully sent data
      print('Message sent successfully');
    } else {
      // Handle error
      print('Error sending message. Status code: ${response.statusCode}');
    }
  }

  void disconnect() {
    stop();
    connected = false;
  }
}
