import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zmoney/fukk_widgets/ngrok.dart';
import 'package:zmoney/welcome_screen.dart';
import 'landing_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _showLoadingTips = false;
  Timer? _loadingTimer;
  final List<String> _visibleReasons = [];
  final List<double> _opacityLevels = []; // Track opacity for each reason
  final List<String> _loadingReasons = [
    "Something is not adding up🤔",
    "Maybe the connection is slow?",
    "Or turned off ..🤭",
    "Check those while waiting here ❤️",
    "We are loading up to no data 💔",
    "Yes still waiting for the server to respond...",
    "Still waiting ...",
    "Cannot connect to the authorization server",
    "Try restarting the app if nothing helps.",
    // Add more reasons here
  ];

  @override
  void initState() {
    super.initState();
    _verifyJwtAndNavigate();
    // Start the timer to show tips after 10 seconds
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _showLoadingTips = true;
      });
      _showReasonsOneByOne();
    });
  }

  void _showReasonsOneByOne() {
    for (int i = 0; i < _loadingReasons.length; i++) {
      Timer(Duration(seconds: 2 * i), () {
        if (i < _loadingReasons.length) {
          setState(() {
            _visibleReasons.add(_loadingReasons[i]);
            _opacityLevels.add(1); // Make visible immediately
          });
        }
      });
    }
  }

  Future<void> _verifyJwtAndNavigate() async {
    String? jwtToken = await _secureStorage.read(key: 'jwtToken');
    if (jwtToken != null) {
      final http.Response playerDataResponse =
          await verifyAndRetrieveData(jwtToken);
      if (playerDataResponse.statusCode == 200) {
        var playerData = jsonDecode(playerDataResponse.body)['playerData'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('playerData', jsonEncode(playerData));
        _navigateToScreen(const LandingPage());
      } else {
        _navigateToScreen(const WelcomeScreen());
      }
    } else {
      _navigateToScreen(const WelcomeScreen());
    }
  }

  Future<http.Response> verifyAndRetrieveData(String jwtToken) async {
    return http.post(
      Uri.parse('${NgrokManager.ngrokUrl}/api/verifyAndRetrieveData'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': jwtToken}),
    );
  }

  void _navigateToScreen(Widget screen) {
    _loadingTimer?.cancel(); // Stop the loading tips timer
    if (mounted) {
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => screen));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/mainscreen.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child:
              _showLoadingTips ? _buildLoadingTips() : _buildLoadingIndicator(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }

  Widget _buildLoadingTips() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _visibleReasons.map((reason) {
          return ListTile(
            title: Text(
              reason,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            leading: const Icon(Icons.info_outline, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }
}
