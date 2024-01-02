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

  @override
  void initState() {
    super.initState();
    client = Client(
      hostname: "127.0.0.0",
      port: 4040,
      onData: onData,
      onError: onError,
    );
  }

  onData(Uint8List data) {
    DateTime time = DateTime.now();
    serverLogs.add("${time.hour}h${time.minute} : ${String.fromCharCodes(data)}");
    setState(() {});
  }

  onError(dynamic error) {
    // ignore: avoid_print
    print(error);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Join Game'),
    ),
    body: Column(
      children: <Widget>[
        // Add IP address input field
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: client.connected ? Colors.green : Colors.red,
                        borderRadius: const BorderRadius.all(Radius.circular(3)),
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
                    print(ipController.text);
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
                  child: ListView(
                    children: serverLogs.map((String log) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(log),
                      );
                    }).toList(),
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
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: const Icon(Icons.clear),
              ),
              const SizedBox(width: 15,),
              MaterialButton(
                onPressed: () {
                  client.write(controller.text);
                  controller.text = "";
                },
                minWidth: 30,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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