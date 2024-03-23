import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final Dio _dio = Dio()
    ..options.connectTimeout = Duration(seconds: 10) // 10 seconds
    ..options.receiveTimeout = Duration(seconds: 10); // 10 seconds
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
      try {
        final Response playerDataResponse =
            await verifyAndRetrieveData(jwtToken);
        if (playerDataResponse.statusCode == 200) {
          // Directly access playerData and inventory from the response
          var playerData = playerDataResponse.data['playerData'];
          var inventoryData = playerDataResponse.data[
              'inventory']; // Updated to access inventory directly from the response

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'playerData', jsonEncode(playerData)); // Storing account info
          await prefs.setString(
              'inventory', jsonEncode(inventoryData)); // Storing inventory info
          print('inventory data: $inventoryData');
          _navigateToScreen(const LandingPage());
        } else {
          _navigateToScreen(const WelcomeScreen());
        }
      } catch (e) {
        print("Error during Dio request: $e");
        _navigateToScreen(const WelcomeScreen());
      }
    } else {
      _navigateToScreen(const WelcomeScreen());
    }
  }

  Future<void> _checkAndRequestStoragePermission() async {
    final storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await _showPermissionRequestDialog();
    }
  }

  Future<void> _showPermissionRequestDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) => AlertDialog(
        title: Text("Storage Permission Needed"),
        content: Text(
            "This app needs storage access to function properly. Without it, some features may not work."),
        actions: <Widget>[
          TextButton(
            child: Text("Understand"),
            onPressed: () {
              Navigator.of(context).pop();
              Permission.storage.request().then((status) {
                // Check permission status
                if (!status.isGranted) {
                  // User denied the permission, handle accordingly
                  _handlePermissionDenied();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _handlePermissionDenied() {
    // Inform the user that the permission was denied and the app's functionality will be limited
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Permission Denied"),
        content: Text(
            "Without storage access, some features may not work properly. Please consider granting it in your app settings if you change your mind."),
        actions: <Widget>[
          TextButton(
            child: Text("Ok"),
            onPressed: () {
              Navigator.of(context).pop();
              // Here, you might want to navigate the user away from features that require the denied permission
            },
          ),
        ],
      ),
    );
  }

  Future<Response> verifyAndRetrieveData(String jwtToken) async {
    return _dio.post(
      '${NgrokManager.ngrokUrl}/api/verifyAndRetrieveData',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {'token': jwtToken},
    );
  }

  void _navigateToScreen(Widget screen) {
    _loadingTimer?.cancel();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => screen));
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
