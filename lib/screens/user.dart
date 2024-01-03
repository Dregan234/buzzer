import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserPage extends StatefulWidget {
  final List<Map<String, dynamic>> players;
  final GlobalKey<UserPageState> userPageKey;
  final Function()? onUpdatePlayers;

  UserPage(
      {required this.players, required this.userPageKey, this.onUpdatePlayers});

  @override
  UserPageState createState() => UserPageState();
}

class UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    // Sort players by points in descending order
    widget.players
        .sort((a, b) => (b['Points'] ?? 0).compareTo(a['Points'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spieler Liste'),
      ),
      body: ListView.builder(
        itemCount: widget.players.length,
        itemBuilder: (context, index) {
          String username = widget.players[index]["Username"] ?? "";
          String ip = widget.players[index]["IP"] ?? "";
          int points = getPointsByIp(ip);
          return ListTile(
            title: Text('$username, Punkte: $points'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      widget.players[index]["Points"] = (points + 1).toString();
                      _savePlayers();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      widget.players[index]["Points"] = (points - 1).toString();
                      _savePlayers();
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void updatePlayersList() {
    // Update the state to trigger a rebuild
    setState(() {});

    // Notify the parent widget to rebuild (if needed)
    if (widget.onUpdatePlayers != null) {
      widget.onUpdatePlayers!();
    }
  }

  void _savePlayers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String playersJson = playersListToJson(widget.players);
    prefs.setString('players', playersJson);
    print("Players saved!");
  }

  int getPointsByIp(String ip) {
  // Retrieve saved points from SharedPreferences based on IP
  Map<String, dynamic>? player = widget.players.firstWhere(
    (player) => player["IP"] == ip,
    orElse: () => <String, String>{}, // Adjust to match the type of list elements
  );

  return player != null ? int.tryParse(player["Points"]?.toString() ?? "0") ?? 0 : 0;
}



  String playersListToJson(List<Map<String, dynamic>> players) {
    // Convert player list to JSON
    return json.encode(players);
  }

  void resetPoints() {
    // Reset points for all players
    for (int i = 0; i < widget.players.length; i++) {
      setState(() {
        widget.players[i]["Points"] = 0.toString();
      });
    }
    _savePlayers(); // Automatically save after resetting points
  }
}
