import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

import 'landing_page.dart';
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

  Widget homeScreen = const WelcomeScreen(); // Default to WelcomeScreen

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    bool isAuthenticated = await PlayGamesService().isAuthenticated();
    await MobileAds.instance.initialize();
    if (isAuthenticated) {
      homeScreen =
          const LandingPage(); // Navigate directly to LandingPage if authenticated
    }
  }

  runApp(MyApp(homeScreen: homeScreen)); // Pass homeScreen to MyApp
}

Future<void> clearSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

class MyApp extends StatelessWidget {
  final Widget homeScreen;

  const MyApp({super.key, required this.homeScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'How Much?',
      home: homeScreen, // Use the passed homeScreen widget
    );
  }
}

// ... Rest of your code for PlayGamesService, WelcomeScreen, etc. ...

class PlayGamesService {
  static const platform = MethodChannel('com.gg.zmoney/play_games');

  Future<bool> isAuthenticated() async {
    if (kDebugMode) {
      print('Checking if user is authenticated...');
    }
    final bool isAuthenticated = await platform.invokeMethod('isAuthenticated');
    if (kDebugMode) {
      print('User authentication status: $isAuthenticated');
    }
    return isAuthenticated;
  }

  Future<void> signIn() async {
    if (kDebugMode) {
      print('Attempting to sign in...');
    }
    await platform.invokeMethod('signIn');
    if (kDebugMode) {
      print('Sign in process initiated');
    }
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  User? currentUser;
  bool showSkipButton = true;
  oauth2.Client? client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _closeKeyboard());
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) {
          print("Google Sign-In was cancelled.");
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (kDebugMode) {
        print("Signed in as: ${userCredential.user?.email}");
      }

      setState(() async {
        currentUser = userCredential.user;

        // Store user information in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('email', currentUser!.email ?? "");
        prefs.setString('displayName', currentUser!.displayName ?? "");
        prefs.setString('userId', currentUser!.uid);
        prefs.setString('idToken', googleAuth.idToken ?? "");
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error during Google Sign-In: $error');
      }
    }
  }

  Widget _buildUserInfo() {
    if (currentUser != null) {
      return Column(
        children: [
          Text('Name: ${currentUser!.displayName ?? "Not available"}'),
          Text('Email: ${currentUser!.email ?? "Not available"}'),
        ],
      );
    }
    return const SizedBox.shrink(); // Empty widget if no user
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _signInWithGoogle,
      child: const Text('Sign in with Google'),
    );
  }

  Widget _buildSkipButton() {
    return Visibility(
      visible: showSkipButton,
      child: TextButton(
        onPressed: () {
          // Directly navigate to the LandingPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        child: const Text('Skip'),
      ),
    );
  }

  Future<void> _signInWithOAuth2() async {
    try {
      // Debug print to indicate the start of the OAuth2 process
      if (kDebugMode) {
        print("Starting OAuth2 sign-in process");
      }

      final authorizationEndpoint =
          Uri.parse('http://example.com/oauth2/authorization');
      final tokenEndpoint = Uri.parse('http://example.com/oauth2/token');
      final redirectUrl = Uri.parse('http://my-site.com/oauth2-redirect');
      const identifier = 'my client identifier';
      const secret = 'my client secret';

      // Specify the path for the credentials file
      final directory = await getApplicationDocumentsDirectory();
      final credentialsFile = File('${directory.path}/credentials.json');

      var exists = await credentialsFile.exists();
      if (kDebugMode) {
        print("Credentials file exists: $exists");
      }

      if (exists) {
        var credentials =
            oauth2.Credentials.fromJson(await credentialsFile.readAsString());
        client =
            oauth2.Client(credentials, identifier: identifier, secret: secret);
        if (kDebugMode) {
          print("OAuth2 client created from existing credentials");
        }
      } else {
        // Logic to handle OAuth2 authorization flow
        if (kDebugMode) {
          print(
              "No existing credentials found, need to start authorization flow");
        }
        // Implement the logic to complete the authorization flow
      }

      if (client != null) {
        if (kDebugMode) {
          print("OAuth2 client is available, saving credentials");
        }
        await credentialsFile.writeAsString(client!.credentials.toJson());
      } else {
        if (kDebugMode) {
          print("OAuth2 client is null, unable to save credentials");
        }
      }
    } catch (e) {
      // Log the error
      if (kDebugMode) {
        print('Error during OAuth2 Sign-In: $e');
      }
    }
  }

  Widget _buildOAuth2SignInButton() {
    return ElevatedButton(
      onPressed:
          _signInWithOAuth2, // Ensure this is correctly referencing your method
      child: const Text('Sign in with OAuth2'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'How Much? Signup - Create your account for the game',
          child: const Text('How Much? Signup'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUserInfo(),
            _buildSignInButton(),
            _buildOAuth2SignInButton(),
            if (showSkipButton) _buildSkipButton(),
          ],
        ),
      ),
    );
  }
}

enum OAuth2LoginStatus { success, cancel, error }

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

class OAuth2LoginResult {
  final OAuth2LoginStatus status;
  final String errorMessage;
  final oauth2.Credentials credential;

  OAuth2LoginResult(this.status, this.errorMessage, this.credential);
}
