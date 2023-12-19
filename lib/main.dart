import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zmoney/landing_page.dart';
// Assuming you have this file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear shared preferences
  await clearSharedPreferences();

  // Environment variable loading and secure storage setup
  String envFileName = ".env";
  if (Platform.isAndroid || Platform.isIOS) {
    // Platform-specific code if needed
  }
  await dotenv.load(fileName: envFileName);
  const secureStorage = FlutterSecureStorage();
  await secureStorage.write(
      key: 'ngrokToken', value: dotenv.env['NGROK_TOKEN']);

  MobileAds.instance.initialize();
  runApp(const MyApp());
}

Future<void> clearSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // This clears all data in SharedPreferences
}

class MyApp extends StatelessWidget {
  // ignore: use_super_parameters
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'App Lottery',
      home: WelcomeScreen(), // Start with WelcomeScreen
    );
  }
}

// WelcomeScreen implementation
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to App Lottery'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // TODO: Implement OAuth2 Login Logic
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LandingPage()));
              },
              child: const Text('Login with OAuth2'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement Google Play Services Login Logic
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LandingPage()));
              },
              child: const Text('Login with Google Play Services'),
            ),
          ],
        ),
      ),
    );
  }
}
