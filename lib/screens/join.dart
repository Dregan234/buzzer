import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:bonobuzzer/classes/client.dart';
import 'package:bonobuzzer/screens/buzzer.dart';
import 'package:bonobuzzer/screens/draw.dart';
import 'package:bonobuzzer/screens/user.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

final GlobalKey<UserPageState> userPageKey = GlobalKey<UserPageState>();

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late Client client;
  List<Map<String, dynamic>> serverLogs = [];
  TextEditingController controller = TextEditingController();
  TextEditingController ipController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  final _networkInfo = NetworkInfo();
  String? ipAddress = 'Loading...';
  bool isExpandedPanel = false;
  bool canTransmit = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _initNetworkInfo();

    // ✅ Use the new multicast-discovering client
    client = Client(
      onData: onData,
      onError: onError,
      onServerFound: onServerFound,
      username: nameController.text,
    );
  }

  // Called when multicast discovers a server
  void onServerFound(String serverAddr) {
    showSnackBarFunc(
        context, "Server gefunden: $serverAddr", const Duration(seconds: 3));
    setState(() {});
  }

  // Handle incoming messages from the server
  void onData(String data) {
    Map<String, dynamic> dict = jsonDecode(data);
    switch (dict["Status"]) {
      case "ImageResponse":
        if (dict["IP"] == ipAddress) {
          showSnackBarFunc(context, "Bild erfolgreich gesendet!",
              const Duration(seconds: 4));
        }
        break;
      case "VersionLow":
        if (dict["IP"] == ipAddress) {
          showSnackBarFunc(context, "Version veraltet, bitte updaten!",
              const Duration(seconds: 20));
        }
        break;
      case "transmitclosed":
        canTransmit = false;
        break;
      case "transmitopen":
        canTransmit = true;
        break;
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

  void onError(dynamic error) {
    developer.log("❌ Client error", error: error);
  }

  void showSnackBarFunc(
      BuildContext context, String message, Duration duration) {
    final dark = isDarkMode(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: dark ? Colors.white : Colors.black,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: dark ? const Color(0xFF00001E) : Colors.grey[300],
        duration: duration,
      ),
    );
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ipController.text = prefs.getString('ip') ?? "";
      nameController.text = prefs.getString('username') ?? "";
    });
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('ip', ipController.text);
    prefs.setString('username', nameController.text);
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

  void clientChat(String name, String mes) {
    DateTime timenow = DateTime.now();
    String time =
        "${timenow.hour.toString().padLeft(2, '0')}:${timenow.minute.toString().padLeft(2, '0')}";
    serverLogs.add({"Time": time, "Username": name, "Message": mes});
    setState(() {});
  }

  Widget _buildChatBubble(Map<String, dynamic> log, BuildContext context) {
    bool dark = isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF00001E) : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log["Username"],
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(log["Message"]),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              log["Time"],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool dark = isDarkMode(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        bool confirmStop = await _showExitDialog(context);
        if (confirmStop) {
          if (client.connected) {
            client.write({
              'Username': nameController.text,
              'Message': "User Disconnected",
              'Status': "disconnected",
              'IP': ipAddress
            });
          }
          client.disconnect();
          serverLogs.clear();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Join Game'),
          actions: [
            IconButton(
              tooltip: "Buzzer",
              icon: const Icon(Icons.music_note_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BuzzerPage(client: client, name: nameController.text),
                ),
              ),
            ),
            IconButton(
              tooltip: "Zeichnen",
              icon: const Icon(Icons.brush_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DrawingPage(
                    client: client,
                    name: nameController.text,
                    ip: ipAddress,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            ExpansionPanelList(
              elevation: 1,
              expandedHeaderPadding: const EdgeInsets.all(15),
              expansionCallback: (_, __) {
                setState(() {
                  isExpandedPanel = !isExpandedPanel;
                });
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) => ListTile(
                    title: Text(
                      'Benutzername',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    leading: Icon(
                      Icons.person,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Benutzername',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _saveData();
                      },
                    ),
                  ),
                  isExpanded: isExpandedPanel,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Client",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          decoration: BoxDecoration(
                            color: client.connected ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            client.connected ? 'Verbunden' : 'Warten...',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: Text(!client.connected
                              ? 'Verbinden'
                              : 'Trennen'),
                          onPressed: () async {
                            if (client.connected) {
                              client.write({
                                'Username': nameController.text,
                                'Message': "User Disconnected",
                                'Status': "disconnected",
                                'IP': ipAddress
                              });
                              client.disconnect();
                              serverLogs.clear();
                              setState(() {});
                            } else {
                              // Validate username
                              if (nameController.text.trim().isEmpty) {
                                showSnackBarFunc(
                                    context,
                                    "Bitte gib einen Benutzernamen ein!",
                                    const Duration(seconds: 3));
                                return;
                              }

                              _saveData();
                              client.username = nameController.text;
                              client.ip = ipAddress ?? "0.0.0.0";

                              await client.start();
                              await client.startMulticastDiscovery();

                              showSnackBarFunc(
                                  context,
                                  "Suche nach Server...",
                                  const Duration(seconds: 3));
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 5),
                        ElevatedButton(
                          onPressed: () => setState(() => serverLogs.clear()),
                          child: const Text('Chat leeren'),
                        ),
                      ],
                    ),
                    const Divider(
                        height: 30, thickness: 1, color: Colors.black12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: serverLogs.length,
                        itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child:
                                _buildChatBubble(serverLogs[index], context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: dark ? const Color(0xFF00001E) : Colors.grey,
              height: 80,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nachricht:',
                          style: TextStyle(
                              fontSize: 8,
                              color: dark ? Colors.white : Colors.black),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            style: TextStyle(
                                color: dark ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  IconButton(
                    icon: Icon(Icons.clear,
                        color: dark ? Colors.white : Colors.black),
                    onPressed: () => controller.clear(),
                  ),
                  const SizedBox(width: 15),
                  IconButton(
                    icon: Icon(Icons.send,
                        color: dark ? Colors.white : Colors.black),
                    onPressed: () {
                      if (controller.text.trim().isEmpty) return;
                      client.write({
                        'Username': nameController.text,
                        'Message': controller.text,
                      });
                      clientChat(nameController.text, controller.text);
                      controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bestätigen'),
            content: const Text('Willst du wirklich verlassen?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Nein')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ja')),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    controller.dispose();
    client.stop();
    super.dispose();
  }
}
