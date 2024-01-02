import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../classes/client.dart';

class JoinScreen extends StatefulWidget {
  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late Client client;
  List<String> serverLogs = [];
  TextEditingController controller = TextEditingController();
  TextEditingController ipController = TextEditingController();
  TextEditingController namecontroller = TextEditingController();

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
  }

  onData(Uint8List data) {
    Map<String, dynamic> dict = jsonDecode(String.fromCharCodes(data));
    DateTime time = DateTime.now();
    serverLogs
    .add("${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} | ${dict["Message"]} | ${dict["Username"]}");
    setState(() {});
  }

  onError(dynamic error) {
    // ignore: avoid_print
    print(error);
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

  Widget _buildChatBubble(String log) {
    List<String> logParts = log.split(" | ");
    String name = logParts.last;
    String message = logParts.length > 1 ? logParts[1] : "";

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[300], // Change color as needed
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
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
              style: TextStyle(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Game'),
      ),
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
                          color: client.connected ? Colors.green : Colors.red,
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
                  ElevatedButton(
                    child: Text(!client.connected ? 'Verbinden' : 'Trennen'),
                    onPressed: () async {
                      client.hostname = ipController.text;
                      _saveData();
                      if (client.connected) {
                        client.disconnect();
                        serverLogs.clear();
                      } else {
                        await client.connect();
                      }
                      setState(() {});
                    },
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
                          child: _buildChatBubble(log),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.grey,
            height: 80,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Nachricht :',
                        style: TextStyle(
                          fontSize: 8,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: controller,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: const Icon(Icons.clear),
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
                    controller.text = "";
                  },
                  minWidth: 30,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: const Icon(Icons.send),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  dispose() {
    controller.dispose();
    client.disconnect();
    super.dispose();
  }
}
