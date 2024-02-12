import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:zmoney/main.dart';
import 'package:zmoney/ngrok.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SideMenuDrawer extends StatefulWidget {
  final List<String> translatedTexts;
  final Color containerColor;

  const SideMenuDrawer({
    super.key,
    required this.translatedTexts,
    required this.containerColor,
  });

  @override
  SideMenuDrawerState createState() => SideMenuDrawerState();
}

class SideMenuDrawerState extends State<SideMenuDrawer> {
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.asset('assets/videos/8s.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController.play();
        _videoPlayerController.setLooping(true);
      });
  }

  void showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.translatedTexts[10]), // Title text for the dialog
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(widget.translatedTexts[11]), // Game Rule 1
                Text(widget.translatedTexts[12]), // Game Rule 2
                // Add more rules as needed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Here we use a Container instead of DrawerHeader to better control the layout
          Container(
            height: 200.0, // Set the initial height for the drawer header
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video background
                _videoPlayerController.value.isInitialized
                    ? VideoPlayer(_videoPlayerController)
                    : Container(color: widget.containerColor),
                // Use Align or Positioned to place text or buttons on the video background
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.translatedTexts[10],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: Icon(Icons.rule),
            title: Text(
                'Rules'), // You might want to use one of the translated texts here
            onTap: () => showRulesDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(widget.translatedTexts[14]), // 'Settings' text
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          // Additional ListTiles for other drawer items...
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  Future<void> _wipePlayerData() async {
    String endpoint = '${NgrokManager.ngrokUrl}/api/zdatawipe';
    try {
      final jwtToken = await _secureStorage.read(key: 'jwtToken');
      print(jwtToken);
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': jwtToken}),
      );

      if (response.statusCode == 200) {
        // Assuming the endpoint returns a success message upon wiping data
        _showMessage('Player data wiped successfully.');
      } else {
        // Handle server errors or invalid responses
        _showMessage('Failed to wipe player data. Please try again.');
      }
    } catch (e) {
      // Handle errors like no internet connection
      _showMessage('An error occurred: $e');
    }
  }

  void _signOut() async {
    // Delete JWT token from secure storage
    await _secureStorage.delete(key: 'jwtToken');

    // Access SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Clear SharedPreferences
    await prefs.clear();

    // Sign out from GoogleSignIn
    try {
      await _googleSignIn
          .signOut(); // Or use disconnect() if you want to revoke access completely
      print("Signed out of Google");
    } catch (error) {
      print("Error signing out of Google: $error");
    }

    // Navigate to WelcomeScreen if the context is still mounted
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()));
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Message"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Wipe Player Data'),
            onTap: _wipePlayerData,
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: _signOut,
          ),
          // Add more settings here as needed
        ],
      ),
    );
  }
}
