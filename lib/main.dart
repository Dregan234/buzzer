import 'package:flutter/material.dart';

import 'package:Bonobuzzer/screens/host.dart';
import 'package:Bonobuzzer/screens/join.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: PopScope(
        canPop: false,
        child: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Multiplayer Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HostScreen()),
                );
              },
              child: const Text('Host Game'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JoinScreen()),
                );
              },
              child: const Text('Join Game'),
            ),
          ],
        ),
      ),
    );
  }
}
