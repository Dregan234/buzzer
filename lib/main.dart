import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bonobuzzer/screens/host.dart';
import 'package:bonobuzzer/screens/join.dart';

import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/",
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF42A5F5),
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF121218),
        ),
        scaffoldBackgroundColor: Color(0xFF121218),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E2E),
          foregroundColor: Colors.white,
        ),
        cardColor: Color(0xFF1E1E2E),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen()
    );
  }
}

class HomeScreen extends StatelessWidget {
  final _audioPlayer = AudioPlayer();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.clear,
              color: Colors.transparent,
            ),
            onPressed: () {
              AssetSource sound = AssetSource("nothing.mp3");
              _audioPlayer.play(sound);
            },
          ),
        ],
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
                  MaterialPageRoute(builder: (context) => const JoinScreen()),
                );
              },
              child: const Text('Join Game'),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 60.0,
        height: 60.0,
        child: IconButton(
          icon: const Icon(
            Icons.clear,
            color: Colors.transparent,
          ),
          onPressed: () {
            AssetSource sound = AssetSource("Yippie.mp3");
            _audioPlayer.play(sound);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
