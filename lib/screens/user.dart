import 'package:Bonobuzzer/screens/points.dart';
import 'package:flutter/material.dart';

class UserPage extends StatefulWidget {
  final List<Map<String, dynamic>> players;

  const UserPage({super.key, required this.players});

  @override
  UserPageState createState() => UserPageState();
}

class UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spielerliste'),
        actions: [
          Tooltip(
            message: "Punkteliste",
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        PointsPage(),
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
              icon: const Icon(Icons.edit_note_outlined),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: widget.players.length,
        itemBuilder: (context, index) {
          String username = widget.players[index]["Username"] ?? "";
          String ip = widget.players[index]["IP"] ?? "";
          return ListTile(title: Text("Name: $username, IP: $ip"));
        },
      ),
    );
  }
}
