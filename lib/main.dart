import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zmoney/welcome_screen.dart';

import 'firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await clearSharedPreferences();

  String envFileName = ".env";
  await dotenv.load(fileName: envFileName);

  const secureStorage = FlutterSecureStorage();
  await secureStorage.write(
      key: 'ngrokToken', value: dotenv.env['NGROK_TOKEN']);

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await PlayGamesService().signIn();

    await MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

Future<void> clearSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'How Much? - The App',
      home: FutureBuilder<bool>(
        future: PlayGamesService().isAuthenticated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              // Proceed to the main screen of the app
              return const WelcomeScreen();
            } else {
              // Show a sign-in screen or a message
              return const SignInScreen(); // Create this widget as per your needs
            }
          }
          return const LoadingScreen(); // Show a loading screen while checking
        },
      ),
    );
  }
}

class PlayGamesService {
  static const platform = MethodChannel('com.gg.zmoney/play_games');

  Future<bool> isAuthenticated() async {
    print('Checking if user is authenticated...');
    final bool isAuthenticated = await platform.invokeMethod('isAuthenticated');
    print('User authentication status: $isAuthenticated');
    return isAuthenticated;
  }

  Future<void> signIn() async {
    print('Attempting to sign in...');
    await platform.invokeMethod('signIn');
    print('Sign in process initiated');
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Sign In Required'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: () async {
              print('Sign in button pressed');
              await PlayGamesService().signIn();
              print('Navigating to WelcomeScreen after sign in');
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()));
            },
            child: const Text('Sign in to Continue'),
          ),
          const SizedBox(height: 20), // Adds some space between the buttons
          ElevatedButton(
            onPressed: () {
              print('Skip sign in button pressed');
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()));
            },
            child: const Text('Skip Sign In'),
          ),
        ],
      ),
    ),
  );
}
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Build your loading screen here
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
