import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Import the confetti package

import 'package:zmoney/landing_page.dart'; // Import the math library

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
