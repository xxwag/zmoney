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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  clearSharedPreferences();

  String envFileName = ".env";
  await dotenv.load(fileName: envFileName);

  const secureStorage = FlutterSecureStorage();
  await secureStorage.write(
      key: 'ngrokToken', value: dotenv.env['NGROK_TOKEN']);

  // Conditional initialization for Android and iOS
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Google Mobile Ads
    MobileAds.instance.initialize();

    // Initialize Play Games Services for Android
    if (Platform.isAndroid) {
      final PlayGamesService playGamesService = PlayGamesService();
      bool isAuthenticated = await playGamesService.isAuthenticated();
      if (isAuthenticated) {
        // If authenticated, get Player ID or perform other actions
        // Use playerId as needed
      }
    }
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
    return const MaterialApp(
      title: 'How Much? - The App',
      home: WelcomeScreen(),
    );
  }
}

class PlayGamesService {
  static const platform = MethodChannel('com.gg.zmoney/play_games');

  Future<bool> isAuthenticated() async {
    final bool isAuthenticated = await platform.invokeMethod('isAuthenticated');
    return isAuthenticated;
  }

  Future<void> requestConsent() async {
    await platform.invokeMethod('requestConsent');
  }

  Future<String> getPlayerId() async {
    final String playerId = await platform.invokeMethod('getPlayerId');
    return playerId;
  }
}
