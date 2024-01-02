import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';

import 'package:buzzer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:buzzer/classes/server.dart';
import 'package:buzzer/screens/user.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

class HostScreen extends StatefulWidget {
  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  late Server server;
  List<String> serverLogs = [];
  TextEditingController controller = TextEditingController();
  String? ipAddress = 'Loading...';
  final _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    server = Server(onData: onData, onError: onError);
    _initNetworkInfo();
  }

  onData(Uint8List data) {
    Map<String, dynamic> dict = jsonDecode(String.fromCharCodes(data));
    DateTime time = DateTime.now();
    serverLogs.add(
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} | ${dict["Message"]} | ${dict["Username"]}");
    setState(() {});
  }

  onError(dynamic error) {
    print(error);
  }

  Future<void> _initNetworkInfo() async {
    String? wifiIPv4;
    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }
    setState(() {
      ipAddress = wifiIPv4;
    });
  }

  Widget _buildChatBubble(String log, BuildContext context) {
    List<String> logParts = log.split(" | ");
    String name = logParts.last;
    String message = logParts.length > 1 ? logParts[1] : "";

    bool isDarkModeActive = isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isDarkModeActive
            ? const Color.fromARGB(255, 0, 0, 30)
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(message),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              logParts[0], // Assuming logParts[0] contains the time
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkModeActive = isDarkMode(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        bool confirmStop = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Bestätigen'),
              content: const Text('Willst du wirklich verlassen?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Nein'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Ja'),
                ),
              ],
            );
          },
        );

        // If the user confirms, stop the server
        if (confirmStop == true) {
          await server.stop();
          serverLogs.clear();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => HomeScreen()));
          });
        }

        // Return false to prevent the default back button behavior
        return Future.value(confirmStop != false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Host'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        UserPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;

                      var tween = Tween(begin: begin, end: end);
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              icon: const FaIcon(FontAwesomeIcons.user),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Server-IP: $ipAddress",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: server.running ? Colors.green : Colors.red,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(3)),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            server.running ? 'ON' : 'OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: Text(server.running ? 'Stop' : 'Start'),
                          onPressed: () async {
                            if (server.running) {
                              await server.stop();
                              serverLogs.clear();
                            } else {
                              await server.start();
                            }
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 5),
                        ElevatedButton(
                          child: const Text('Chat leeren'),
                          onPressed: () {
                            setState(() {
                              serverLogs.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(
                      height: 30,
                      thickness: 1,
                      color: Colors.black12,
                    ),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: serverLogs.length,
                        itemBuilder: (context, index) {
                          String log = serverLogs[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: _buildChatBubble(log, context),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: isDarkModeActive
                  ? const Color.fromARGB(255, 0, 0, 30)
                  : Colors.grey,
              height: 80,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Host Nachricht :',
                          style: TextStyle(
                            fontSize: 8,
                            color:
                                isDarkModeActive ? Colors.white : Colors.black,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: controller,
                            style: TextStyle(
                              color: isDarkModeActive
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  MaterialButton(
                    onPressed: () {
                      controller.text = "";
                    },
                    minWidth: 30,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    child: Icon(
                      Icons.clear,
                      color: isDarkModeActive ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  MaterialButton(
                    onPressed: () {
                      server.broadCast({
                        'Username': 'Host',
                        'Message': controller.text,
                      });
                      controller.text = "";
                    },
                    minWidth: 30,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    child: Icon(
                      Icons.send,
                      color: isDarkModeActive ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
