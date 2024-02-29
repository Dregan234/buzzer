import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';

import 'package:Bonobuzzer/screens/buzzer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;

import 'package:Bonobuzzer/classes/server.dart';
import 'package:Bonobuzzer/screens/user.dart';
import 'package:Bonobuzzer/models/version.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  late Server server;
  List<Map<String, dynamic>> serverLogs = [];
  List<Map<String, String>> players = [];
  List<String> playerIPS = [];
  TextEditingController controller = TextEditingController();
  final _audioPlayer = AudioPlayer();
  String? ipAddress = 'Loading...';
  final _networkInfo = NetworkInfo();
  bool isSoundPlaying = false;

  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    server = Server(onData: onData, onError: onError, onGetAlive: onGetAlive);
    _initNetworkInfo();
  }

  void checkVersion(String clientVersion, String hostVersion, String? ip) {
    List<int> clientVersionNumbers =
        clientVersion.split('.').map(int.parse).toList();
    List<int> hostVersionNumbers =
        hostVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (clientVersionNumbers[i] < hostVersionNumbers[i]) {
        server.response({
          "Status": "VersionLow",
          "IP": ip,
        }, ip);
        return;
      } else if (clientVersionNumbers[i] > hostVersionNumbers[i]) {
        showSnackBarFunc(context);
        return;
      }
    }
    print("Client and host versions are the same.");
  }

  showSnackBarFunc(context) {
    SnackBar snackBar = SnackBar(
      content: Text(
        "Version veraltet, bitte updaten!",
        style: TextStyle(
          color: isDarkMode(context) ? Colors.white : Colors.black,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
        ),
      ),
      backgroundColor:
          isDarkMode(context) ? Color.fromARGB(255, 0, 0, 0) : Colors.grey[300],
      duration: Duration(seconds: 20),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void onGetAlive(String data) {
    Map<String, dynamic> dict = jsonDecode(data);
    String username = dict["Username"];
    String ip = dict["IP"] ?? "Null";

    players
        .removeWhere((player) => player["IP"] == ip && !playerIPS.contains(ip));

    if (!playerIPS.contains(ip)) {
      players.add({"Username": username, "IP": ip});
      playerIPS.add(ip);
    }
  }

  void onData(String data) {
    Map<String, dynamic> dict = jsonDecode(data);
    switch (dict["Status"]) {
      case "connected":
        String username = dict["Username"];
        String ip = dict["IP"] ?? "Null";
        String version = dict["Version"];

        bool ipExists = players.any((player) => player["IP"] == ip);

        if (!ipExists) {
          players.add({"Username": username, "IP": ip});
          playerIPS.add(ip);
        } else {
          print('Player $username with IP $ip already exists.');
        }

        checkVersion(version, globalAppVersion, ip);

        DateTime timeConnected = DateTime.now();
        String time =
            "${timeConnected.hour.toString().padLeft(2, '0')}:${timeConnected.minute.toString().padLeft(2, '0')}";
        serverLogs.add({
          "Time": time,
          "Username": dict["Username"] + " connected",
          "Message": dict["Username"] + " connected"
        });
        setState(() {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
        break;

      case "disconnected":
        String ip = dict["IP"] ?? "Null";

        players.removeWhere((player) => player["IP"] == ip);
        playerIPS.remove(ip);

        DateTime timeDisconnected = DateTime.now();
        String time =
            "${timeDisconnected.hour.toString().padLeft(2, '0')}:${timeDisconnected.minute.toString().padLeft(2, '0')}";
        serverLogs.add({
          "Time": time,
          "Username": dict["Username"] + " disconnected",
          "Message": dict["Username"] + " disconnected"
        });
        setState(() {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
        break;

      case "Buzzer":
        if (!isSoundPlaying) {
          isSoundPlaying = true;
          String buzzerstring = dict["Sound"] ?? "buzzer.mp3";
          DateTime now = DateTime.now();
          String currentTime =
              "${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond}";
          AssetSource buzzersound = AssetSource(buzzerstring);

          _audioPlayer.play(buzzersound);

          dict["Message"] = "${dict["Message"]} $currentTime";
          DateTime timenow = DateTime.now();
          String time =
              "${timenow.hour.toString().padLeft(2, '0')}:${timenow.minute.toString().padLeft(2, '0')}";
          serverLogs.add({
            "Time": time,
            "Username": dict["Username"],
            "Message": dict["Message"]
          });
          setState(() {});

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });

          Future.delayed(const Duration(seconds: 2), () {
            isSoundPlaying = false;
          });
        }
        break;

      case "SVG":
        String completeSVGData = dict["SVG-data"];
        DateTime timesvg = DateTime.now();
        String time =
            "${timesvg.hour.toString().padLeft(2, '0')}:${timesvg.minute.toString().padLeft(2, '0')}";

        serverLogs.add({
          "Time": time,
          "Username": dict["Username"],
          "Message": completeSVGData,
          "SVG": true
        });
        setState(() {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
        break;

      default:
        DateTime timeDefault = DateTime.now();
        String time =
            "${timeDefault.hour.toString().padLeft(2, '0')}:${timeDefault.minute.toString().padLeft(2, '0')}";
        serverLogs.add({
          "Time": time,
          "Username": dict["Username"],
          "Message": dict["Message"]
        });
        setState(() {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
        break;
    }
  }

  onError(dynamic error) {
    // ignore: avoid_print
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

  Widget _buildChatBubble(Map<String, dynamic> log, BuildContext context) {
    String name = log["Username"];
    String message = log["Message"];
    bool isDarkModeActive = isDarkMode(context);

    if (log["SVG"] == true) {
      message = checkAndFixSvgData(message);
    }

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
          GestureDetector(
            onTap: () {
              if (log["SVG"] == true) {
                _showImageDialog(context, message);
              }
            },
            child: log["SVG"] == true
                ? SvgPicture.string(
                    message,
                    width: 200,
                    height: 200,
                  )
                : Text(message),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              log["Time"],
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

  void _showImageDialog(BuildContext context, String svgString) {
    double width = 300;
    double height = 300;

    final document = xml.XmlDocument.parse(svgString);
    final svgNode = document.rootElement;

    final widthAttribute = svgNode.getAttribute('width');
    final heightAttribute = svgNode.getAttribute('height');

    if (widthAttribute != null) {
      width = double.tryParse(widthAttribute) ?? width;
    }
    if (heightAttribute != null) {
      height = double.tryParse(heightAttribute) ?? height;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: width,
            height: height,
            child: Center(
              child: SvgPicture.string(svgString),
            ),
          ),
        );
      },
    );
  }

  String checkAndFixSvgData(String data) {
    String fixedData = data;
    // Check for missing '<' or '>'
    if (!data.contains('<')) {
      fixedData = '<$fixedData';
    }
    if (!data.contains('>')) {
      fixedData = '$fixedData>';
    }
    return fixedData;
  }

  Future<void> _showVersionInfo(BuildContext context) async {
    final appVersion = globalAppVersion;
    final makerName = "Von Bonobos für Bonobos";

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Info'),
          actions: <Widget>[
            ListTile(
              title: Text('Version: $appVersion'),
            ),
            ListTile(
              title: Text('Ersteller: $makerName'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkModeActive = isDarkMode(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        bool confirmStop = await showDialog(
          barrierDismissible: false,
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
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          });
        }

        // Return false to prevent the default back button behavior
        // ignore: void_checks
        return Future.value(confirmStop != false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              AssetSource sound = AssetSource("gay.mp3");
              _audioPlayer.play(sound);
            },
            child: const Text('Host'),
          ),
          actions: [
            Tooltip(
                message: "Buzzer",
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            BuzzerPage(client: server, name: "Host"),
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
                  icon: const Icon(Icons.music_note_outlined),
                )),
            Tooltip(
              message: "Spielerliste",
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          UserPage(players: players),
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
                        GestureDetector(
                          onTap: () {
                            _showVersionInfo(context);
                          },
                          child: Text(
                            "Server-IP: $ipAddress",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
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
                        controller: _scrollController,
                        itemCount: serverLogs.length,
                        itemBuilder: (context, index) {
                          if (index >= serverLogs.length) {
                            return SizedBox();
                          }
                          Map<String, dynamic>? log = serverLogs[index];
                          if (!log.containsKey("Username") ||
                              !log.containsKey("Time")) {
                            return SizedBox();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 15),
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
                      }, playerIPS);
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
