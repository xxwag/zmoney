import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:window_manager/window_manager.dart';

import 'package:zmoney/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads
  MobileAds.instance.initialize();

  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Set the desired window size (e.g., 800x600)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 450),
    center: true, // Center the window
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
