import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;

import 'package:zmoney/fukk_widgets/translator.dart';
import 'package:zmoney/loading_screen.dart';
import 'package:zmoney/ngrok.dart';
import 'firebase_options.dart';
import 'package:games_services/games_services.dart';
import 'package:auto_localization/auto_localization.dart';

final translator =
    Translator(currentLanguage: 'en'); // Set initial language as needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String envFileName = ".env";
  await dotenv.load(fileName: envFileName);

  const secureStorage = FlutterSecureStorage();
  await secureStorage.write(
      key: 'ngrokToken', value: dotenv.env['NGROK_TOKEN']);
  // Fetch Ngrok data
  await NgrokManager.fetchNgrokData();
  runApp(MyApp(homeScreen: const LoadingScreen()));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance
      .activate(androidProvider: AndroidProvider.playIntegrity);

  // Assuming this code is inside an async function
  String userLanguage =
      await getPreferredLanguage(); // Notice the 'await' keyword
// await clearSharedPreferences(); // Uncomment this if you need to clear SharedPreferences
  const String preferredLanguage = 'en'; // Example language code
  translator.setCurrentLanguage(preferredLanguage);

  await AutoLocalization.init(
    appLanguage: 'en', // Default language
    userLanguage: userLanguage, // Use the awaited userLanguage
  );
  GamesServices.signIn();
}

Future<String> getPreferredLanguage() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? userLanguage = prefs.getString('userLanguage');

  if (userLanguage != null) {
    return userLanguage;
  } else {
    return PlatformDispatcher.instance.locales.first.languageCode;
  }
}

Future<void> clearSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

class MyApp extends StatelessWidget {
  final Widget homeScreen;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  const MyApp({super.key, required this.homeScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'How Much?',
      navigatorKey: navigatorKey,
      home: homeScreen, // Use the passed homeScreen widget
    );
  }
}
