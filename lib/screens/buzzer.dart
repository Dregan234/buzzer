import 'package:Bonobuzzer/classes/client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class BuzzerPage extends StatefulWidget {
  final Client client;
  String name;

  BuzzerPage({super.key, required this.client, required this.name});

  @override
  // ignore: library_private_types_in_public_api
  _BuzzerPageState createState() => _BuzzerPageState();
}

class _BuzzerPageState extends State<BuzzerPage> {
  late SharedPreferences _prefs;
  String selectedSound = 'buzzer.mp3'; // Default sound

  @override
  void initState() {
    super.initState();
    _loadSelectedSound();
  }

  Future<void> _loadSelectedSound() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSound = _prefs.getString('selectedSound') ?? 'buzzer.mp3';
    });
  }

  Future<void> _saveSelectedSound(String soundValue) async {
    setState(() {
      selectedSound = soundValue;
    });
    await _prefs.setString('selectedSound', soundValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buzzer Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSoundSelectionMenu(context);
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            widget.client.write({
              'Username': widget.name,
              'Message': "Hat den Buzzer gedruckt um: ",
              "Status": "Buzzer",
              "Sound": selectedSound,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.all(100.0),
            shape: const CircleBorder(),
            elevation: 5,
          ),
          child: const Text(
            'Press me',
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }

  void _showSoundSelectionMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSoundTile('Buzzer', 'buzzer.mp3'),
            _buildSoundTile('Hallo', 'Hallo.mp3'),
            _buildSoundTile('Kugelfisch', 'puff.mp3'),
            _buildSoundTile('Schildkröte', 'turtle.mp3'),
            _buildSoundTile('Yippie', 'Yippie.mp3'),
            _buildSoundTile("Finds heraus", "nothing.mp3"),
            _buildSoundTile("Alarm", "alarm.mp3"),
            _buildSoundTile("SUS", "among.mp3"),
            _buildSoundTile("Halt", "halt.mp3"),
            _buildSoundTile("UwU", "uwu.mp3")
          ],
        ),
      );
    },
  );
}

  Widget _buildSoundTile(String soundName, String soundValue) {
    return ListTile(
      title: Row(
        children: [
          Text(soundName),
          if (selectedSound == soundValue)
            const Icon(
              Icons.check,
              color: Colors.green,
            ),
        ],
      ),
      onTap: () {
        _saveSelectedSound(soundValue);
        Navigator.pop(context);
      },
    );
  }
}
