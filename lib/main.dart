import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Import the confetti package

import 'package:zmoney/landing_page.dart'; // Import the math library

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  final secureStorage = FlutterSecureStorage();

  WidgetsFlutterBinding.ensureInitialized();
  // Store the token in secure storage
  await secureStorage.write(
      key: 'ngrokToken', value: dotenv.env['NGROK_TOKEN']);

  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'App Lottery',
      home: LandingPage(),
    );
  }
}
