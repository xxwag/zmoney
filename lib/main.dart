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

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Size> _windowSizes = [
    const Size(450, 800),
    const Size(600, 1200),
    const Size(1024, 768),
  ];
  int _currentSizeIndex = 0;

  void _changeWindowSize() async {
    setState(() {
      _currentSizeIndex = (_currentSizeIndex + 1) % _windowSizes.length;
    });

    WindowOptions windowOptions = WindowOptions(
      size: _windowSizes[_currentSizeIndex],
      center: true,
    );
    await windowManager.setSize(windowOptions.size!);
    await windowManager.center();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Lottery',
      home: Scaffold(
        body: const LandingPage(),
        floatingActionButton: FloatingActionButton(
          onPressed: _changeWindowSize,
          child: const Icon(Icons.aspect_ratio),
        ),
      ),
    );
  }
}
