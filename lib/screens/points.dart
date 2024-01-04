import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  PointsPageState createState() => PointsPageState();
}

class PointsPageState extends State<PointsPage> {
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    // Sort players by points in descending order
    players.sort((a, b) => (b['Points'] ?? "0").compareTo(a['Points'] ?? "0"));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punkteliste'),
      ),
      body: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          String username = players[index]["Username"] ?? "";
          int points = getPointsByIndex(index);
          return ListTile(
            title: Text('$username, Punkte: $points'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _updatePoints(index, points + 1);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    _updatePoints(index, points - 1);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _removePlayer(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: 'Spieler hinzufügen',
          child: FloatingActionButton(
            heroTag: "btn1",
            onPressed: _addPlayer,
            child: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 16.0),
        Tooltip(
          message: 'Alles zurücksetzen',
          child: FloatingActionButton(
            heroTag: "btn2",
            onPressed: _resetAllPlayers,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    ),
    );
  }

  void _savePlayers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String playersJson = playersListToJson(players);
    prefs.setString('players', playersJson);
    print("Players saved!");
  }

  void _loadPlayers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? playersJson = prefs.getString('players');
    if (playersJson != null) {
      List<Map<String, dynamic>> loadedPlayers =
          List<Map<String, dynamic>>.from(json.decode(playersJson));
      setState(() {
        players = loadedPlayers;
      });
    }
  }

  int getPointsByIndex(int index) {
    return int.tryParse(players[index]["Points"]?.toString() ?? "0") ?? 0;
  }

  String playersListToJson(List<Map<String, dynamic>> players) {
    return json.encode(players);
  }

  void _addPlayer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String username = "";
        return AlertDialog(
          title: const Text("Spieler hinzufügen"),
          content: TextField(
            onChanged: (value) {
              username = value;
            },
            decoration: const InputDecoration(labelText: "Username eingeben"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  players.add({"Username": username, "Points": "0"});
                  _savePlayers();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _updatePoints(int index, int newPoints) {
    setState(() {
      players[index]["Points"] = newPoints.toString();
      _savePlayers();
    });
  }

  void _removePlayer(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Spieler entfernen"),
          content: const Text("Bist du sicher, "
          "dass du diesen Spieler entfernen möchtest?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  players.removeAt(index);
                  _savePlayers();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );
  }

  void _resetAllPlayers() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Reset All Players"),
        content: const Text("Bist du sicher, "
        "dass du alles zurücksetzen willst?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                players.clear();
                _savePlayers();
              });
              Navigator.of(context).pop();
            },
            child: const Text("Alles zurücksetzen"),
          ),
        ],
      );
    },
  );
}
}