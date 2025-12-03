// lib/classes/client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

typedef StringCallback = void Function(String);
typedef DynamicCallback = void Function(dynamic);

class Client {
  Client({
    this.onError,
    this.onData,
    this.onServerFound,
    this.username = "Client",
  });

  StringCallback? onData;
  DynamicCallback? onError;
  StringCallback? onServerFound;

  String username;
  String ip = "";
  String? serverIp;
  int serverPort = 4040;

  bool connected = false;
  bool running = false;

  http.Client httpClient = http.Client();
  HttpServer? server;

  Timer? aliveTimer;
  RawDatagramSocket? multicastSocket;

  // Multicast discovery parameters
  final String multicastGroup = '239.255.255.250';
  final int multicastPort = 1900;

  // ---------------------------
  // 🚀 Start and Stop
  // ---------------------------

  Future<void> start() async {
    try {
      // Start local HTTP listener for incoming POSTs (from server)
      server = await HttpServer.bind('0.0.0.0', 4040);
      running = true;
      server!.listen(onRequest);

      print("✅ Client started.");
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> stop() async {
    await server?.close();
    server = null;
    running = false;

    aliveTimer?.cancel();
    multicastSocket?.close();
    connected = false;

    print("🛑 Client stopped.");
  }

  // ---------------------------
  // 📡 Multicast Discovery
  // ---------------------------

  Future<void> startMulticastDiscovery() async {
    await _startMulticastListener();
  }

  Future<void> _startMulticastListener() async {
    try {
      multicastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        multicastPort,
        reuseAddress: true,
        reusePort: true,
      );

      multicastSocket!.joinMulticast(InternetAddress(multicastGroup));

      multicastSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = multicastSocket!.receive();
          if (datagram == null) return;

          final message = utf8.decode(datagram.data);
          try {
            final decoded = jsonDecode(message);
            if (decoded['type'] == 'server_announce') {
              final ip = decoded['ip'];
              final port = decoded['port'];

              if (!connected) {
                _connectToServer(ip, port);
              }
            }
          } catch (_) {
            // ignore malformed packets
          }
        }
      });
    } catch (e) {
      print("❌ Failed to join multicast group: $e");
    }
  }

  Future<void> _connectToServer(String ip, int port) async {
    serverIp = ip;
    serverPort = port;
    connected = true;

    print("🔗 Server discovered at $ip:$port");
    onServerFound?.call("$ip:$port");

    await _getLocalIp();
    startSendingPeriodicAlive();
  }

  // ---------------------------
  // 🌐 HTTP Handling
  // ---------------------------

  void onRequest(HttpRequest request) async {
    if (request.method == 'POST' && request.uri.path == '/data') {
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
      onData?.call(jsonString);

      request.response
        ..statusCode = HttpStatus.ok
        ..write('OK')
        ..close();
    } catch (e) {
      onError?.call(e);
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Error handling POST: $e')
        ..close();
    }
  }

  // ---------------------------
  // 💬 Communication
  // ---------------------------

  void write(Map<String, dynamic> messageMap) async {
    if (serverIp == null) {
      print("⚠️ No server connected yet.");
      return;
    }

    try {
      final response = await httpClient.post(
        Uri.parse('http://$serverIp:$serverPort/data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(messageMap),
      );

      if (response.statusCode == 200) {
        print('📤 Data sent successfully to server.');
      } else {
        print('❌ Error sending data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error writing to server: $e');
    }
  }

  // ---------------------------
  // 🔁 Periodic Alive Messages
  // ---------------------------

  void startSendingPeriodicAlive() {
    aliveTimer?.cancel();
    aliveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      sendAlive();
    });
  }

  Future<void> sendAlive() async {
    if (serverIp == null) return;

    final uri = Uri.parse(
      'http://$serverIp:$serverPort/alive?ip=$ip&name=$username',
    );

    try {
      final response = await httpClient.get(uri);
      if (response.statusCode == 200) {
        print('💚 Alive sent successfully.');
      } else {
        print('⚠️ Alive failed with code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending alive: $e');
    }
  }

  Future<void> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var i in interfaces) {
        for (var addr in i.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127')) {
            ip = addr.address;
            return;
          }
        }
      }
    } catch (_) {}
    ip = '0.0.0.0';
  }

  // ---------------------------
  // 🧹 Cleanup
  // ---------------------------

  void disconnect() {
    stop();
    print("🔌 Disconnected from server.");
  }
}
