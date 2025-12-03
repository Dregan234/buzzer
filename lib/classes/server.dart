// lib/classes/server.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

typedef StringCallback = void Function(String);
typedef DynamicCallback = void Function(dynamic);

class Server {
  Server({this.onError, this.onData, this.onGetAlive});

  StringCallback? onData;
  StringCallback? onGetAlive;
  DynamicCallback? onError;
  HttpServer? server;
  bool running = false;
  http.Client httpClient = http.Client();

  // Multicast settings
  RawDatagramSocket? multicastSocket;
  Timer? multicastTimer;
  final String multicastGroup = '239.255.255.250';
  final int multicastPort = 1900;

  /// Start both HTTP server and multicast announcements
  Future<void> start() async {
    try {
      server = await HttpServer.bind('0.0.0.0', 4040);
      running = true;
      server!.listen(onRequest);

      _startMulticastBroadcast();

      Map<String, dynamic> messageMap = {
        'Username': 'Server',
        'Message': 'Server listening on port 4040',
      };

      onData?.call(jsonEncode(messageMap));
    } catch (e) {
      onError?.call(e);
    }
  }

  /// Stop both HTTP and multicast
  Future<void> stop() async {
    await server?.close();
    server = null;
    multicastTimer?.cancel();
    multicastSocket?.close();
    running = false;
  }

  /// Handles incoming HTTP requests
  void onRequest(HttpRequest request) async {
    if (request.method == 'POST' && request.uri.path == '/data') {
      await handlePost(request);
    } else if (request.method == 'GET' && request.uri.path == '/alive') {
      await handleGetAlive(request);
    } else {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${request.method}.')
        ..close();
    }
  }

  Future<void> handleGetAlive(HttpRequest request) async {
    final queryParams = request.uri.queryParameters;
    final ipparam = queryParams["ip"];
    final nameparam = queryParams["name"];
    var jsonString = jsonEncode({"Username": nameparam, "IP": ipparam});
    onGetAlive?.call(jsonString);
  }

  Future<void> handlePost(HttpRequest request) async {
    var jsonString = await utf8.decoder.bind(request).join();
    onData?.call(jsonString);
  }

  /// Broadcasts messages to a list of IPs
  void broadCast(Map<String, dynamic> messageMap, List<String> iplist) {
    for (var ip in iplist) {
      response(messageMap, ip);
    }
  }

  Future<void> response(Map<String, dynamic> messageMap, String hostname) async {
    try {
      String jsonString = jsonEncode(messageMap);
      final response = await httpClient.post(
        Uri.parse('http://$hostname:4040/data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonString,
      );
      if (response.statusCode != 200) {
        print('❌ Error sending data to $hostname: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error writing to server: $e');
    }
  }

  void write(Map<String, dynamic> messageMap) {
    String jsonString = jsonEncode(messageMap);
    onData?.call(jsonString);
  }

  // ---------------------------
  // 🔊 Multicast Discovery Logic
  // ---------------------------

  Future<void> _startMulticastBroadcast() async {
    try {
      multicastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      multicastTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        final ip = await _getLocalIp();
        final announce = jsonEncode({
          'type': 'server_announce',
          'ip': ip,
          'port': 4040,
        });
        multicastSocket!.send(
          utf8.encode(announce),
          InternetAddress(multicastGroup),
          multicastPort,
        );
        print("📡 Broadcasting server: $ip:4040");
      });
    } catch (e) {
      print("❌ Failed to start multicast broadcast: $e");
    }
  }
  Future<String> _getLocalIp() async {
    // Return local network IP (best effort)
    try {
      final interfaces = await NetworkInterface.list();
      for (var i in interfaces) {
        for (var addr in i.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
