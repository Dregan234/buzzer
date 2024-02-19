import 'dart:developer' as developer;
import 'dart:convert';

import 'package:Bonobuzzer/models/version.dart';
import 'package:Bonobuzzer/screens/buzzer.dart';
import 'package:Bonobuzzer/screens/draw.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:Bonobuzzer/classes/client.dart';
import 'package:Bonobuzzer/screens/user.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

final GlobalKey<UserPageState> userPageKey = GlobalKey<UserPageState>();

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late Client client;
  List<Map<String, dynamic>> serverLogs = [];
  List<Map<String, String>> players = [];
  TextEditingController controller = TextEditingController();
  TextEditingController ipController = TextEditingController();
  TextEditingController namecontroller = TextEditingController();
  final _networkInfo = NetworkInfo();
  String? ipAddress = 'Loading...';
  bool isExpandedPanel = false;
  bool canTransmit = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    client = Client(
      hostname: "127.0.0.0",
      port: 4040,
      onData: onData,
      onError: onError,
    );
    _initNetworkInfo();
  }

  onData(String data) {
    Map<String, dynamic> dict = jsonDecode(data);
    switch (dict["Status"]) {
      case "ImageResponse":
        if (dict["IP"] == ipAddress) {
          String message = "Bild erfolgreich gesendet!";
          Duration duration = Duration(seconds: 4);
          showSnackBarFunc(context, message, duration);
        }
        break;
      case "VersionLow":
        if (dict["IP"] == ipAddress) {
          String message = "Version veraltet, bitte updaten!";
          Duration duration = Duration(seconds: 20);
          showSnackBarFunc(context, message, duration);
        }
      case "transmitclosed":
        canTransmit = false;
      case "transmitopen":
        canTransmit = true;
      default:
        DateTime timenow = DateTime.now();
        String time =
            "${timenow.hour.toString().padLeft(2, '0')}:${timenow.minute.toString().padLeft(2, '0')}";
        serverLogs.add({
          "Time": time,
          "Username": dict["Username"],
          "Message": dict["Message"]
        });
        setState(() {});
        break;
    }
  }

  onError(dynamic error) {
    // ignore: avoid_print
    print(error);
  }

  showSnackBarFunc(BuildContext context, String message, Duration duration) {
    SnackBar snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isDarkMode(context) 
          ? Colors.white 
          : Colors.black,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
        ),
      ),
      backgroundColor: isDarkMode(context)
          ? const Color.fromARGB(255, 0, 0, 30)
          : Colors.grey[300],
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ipController.text = prefs.getString('ip') ?? "127.0.0.0";
      namecontroller.text = prefs.getString('username') ?? "";
    });
  }

  _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('ip', ipController.text);
    prefs.setString('username', namecontroller.text);
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

  clientChat(String name, String mes) {
    DateTime timenow = DateTime.now();
    String time =
        "${timenow.hour.toString().padLeft(2, '0')}:${timenow.minute.toString().padLeft(2, '0')}";
    serverLogs.add({"Time": time, "Username": name, "Message": mes});
    setState(() {});
  }

  Widget _buildChatBubble(Map<String, dynamic> log, BuildContext context) {
    String name = log["Username"];
    String message = log["Message"];

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
            client.write({
              'Username': namecontroller.text,
              'Message': "User Disconnected",
              'Status': "disconnected",
              'IP': ipAddress
            });
            client.disconnect();
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
            title: const Text('Join Game'),
            actions: [
              Tooltip(
                  message: "Buzzer",
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  BuzzerPage(
                                      client: client,
                                      name: namecontroller.text),
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
                message: "Zeichnen",
                child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  DrawingPage(
                                      client: client,
                                      name: namecontroller.text,
                                      ip: ipAddress),
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
                    icon: const Icon(Icons.brush_outlined)),
              )
            ],
          ),
          body: Column(
            children: <Widget>[
              ExpansionPanelList(
                elevation: 1,
                expandedHeaderPadding: const EdgeInsets.all(15),
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    // Toggle the expansion state
                    isExpandedPanel = !isExpandedPanel;
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      // Removed the Text widget
                      return Container();
                    },
                    body: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: TextField(
                            controller: ipController,
                            decoration: const InputDecoration(
                              labelText: 'Enter IP Address',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: TextField(
                            controller: namecontroller,
                            decoration: const InputDecoration(
                              labelText: 'Enter Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    isExpanded: isExpandedPanel,
                  ),
                ],
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            "Client",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  client.connected ? Colors.green : Colors.red,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(3)),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              client.connected ? 'Verbunden' : 'Getrennt',
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
                            child: Text(
                                !client.connected ? 'Verbinden' : 'Trennen'),
                            onPressed: () async {
                              client.hostname = ipController.text;
                              _saveData();
                              if (client.connected) {
                                client.write({
                                  'Username': namecontroller.text,
                                  'Message': "User Disconnected",
                                  'Status': "disconnected",
                                  'IP': ipAddress
                                });
                                client.disconnect();
                                serverLogs.clear();
                              } else {
                                await client.connect();
                                client.write({
                                  'Username': namecontroller.text,
                                  'Message': "User Connected",
                                  'Status': "connected",
                                  'IP': ipAddress,
                                  "Version": globalAppVersion
                                });
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
                            Map<String, dynamic> log = serverLogs[index];
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
                            'Nachricht :',
                            style: TextStyle(
                              fontSize: 8,
                              color: isDarkModeActive
                                  ? Colors.white
                                  : Colors.black,
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
                    const SizedBox(
                      width: 15,
                    ),
                    MaterialButton(
                      onPressed: () {
                          client.write({
                          'Username': namecontroller.text,
                          'Message': controller.text,
                        });
                        clientChat(namecontroller.text, controller.text);
                        controller.text = "";
                      },
                      minWidth: 30,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Icon(
                        Icons.send,
                        color: isDarkModeActive ? Colors.white : Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }
}
