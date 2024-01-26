import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:zmoney/loading_screen.dart';

import 'landing_page.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start with LoadingScreen to prevent a blank screen during initialization
  Widget homeScreen = const LoadingScreen();

  // Run the app with the LoadingScreen
  runApp(MyApp(homeScreen: homeScreen));

  clearSharedPreferences();

  String envFileName = ".env";
  await dotenv.load(fileName: envFileName);

  const secureStorage = FlutterSecureStorage();
  await secureStorage.write(
      key: 'ngrokToken', value: dotenv.env['NGROK_TOKEN']);

  // Check platform and initialize services
  if (Platform.isAndroid || Platform.isIOS) {
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    bool isAuthenticated = await verifyUserAuthentication();
    MobileAds.instance.initialize();

    // Check for stored user tokens
    String? userToken = await secureStorage.read(key: 'userToken');
    String? oauthToken = await secureStorage.read(key: 'oauthToken');

    // Update the homeScreen based on authentication status
    homeScreen = isAuthenticated ? const LandingPage() : const WelcomeScreen();
  } else {
    // For other platforms, default to WelcomeScreen
    homeScreen = const WelcomeScreen();
  }

  // Update the app to show the appropriate screen after initialization
  Future.delayed(Duration(seconds: 3), () {
    // Delay of 3 seconds
    // Now run the app
    runApp(MyApp(homeScreen: homeScreen));
  });
}

Future<bool> verifyUserAuthentication() async {
  const secureStorage = FlutterSecureStorage();
  String? userToken = await secureStorage.read(key: 'userToken');

  if (userToken == null) return false;

  try {
    var response = await http.post(
      Uri.parse('http://your-node-js-api.com/verifyCredentials'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': userToken}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['isAuthenticated'];
    } else {
      // Handle server error
      return false;
    }
  } catch (e) {
    // Handle connection error
    return false;
  }
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

      if (userCredential.user != null) {
        String? email = userCredential.user?.email;
        if (email != null) {
          final response = await approachMasterEndpoint(email);
          // Handle response accordingly
          // ...
        } else {
          // Handle the case where email is null
          if (kDebugMode) {
            print("Email is null. Cannot approach master endpoint.");
          }
        }

        setState(() {
          currentUser = userCredential.user;
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error during Google Sign-In: $error');
      }
    }
  }

  Future<dynamic> approachMasterEndpoint(String email) async {
    // Build the request to the masterEndpoint
    var response = await http.post(
      Uri.parse('http://your-node-js-api.com/masterEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'register', // or another appropriate action
        'email': email,
        // Include other necessary data
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data;
    } else {
      // Handle errors or invalid responses
      return null;
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
    final List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email'
    ];

    try {
      if (kDebugMode) {
        print("Starting OAuth2 sign-in process");
      }

      final authorizationEndpoint =
          Uri.parse('https://accounts.google.com/o/oauth2/auth');
      final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');
      final redirectUrl = Uri.parse('com.gg.zmoney://oauth2redirect');
      const identifier =
          '446412900874-iu52p62l44up39q0u3m3gtlr3sm55fih.apps.googleusercontent.com';
      const secret = ''; // Public clients typically don't have a secret

      final directory = await getApplicationDocumentsDirectory();
      final credentialsFile = File('${directory.path}/credentials.json');
      var exists = await credentialsFile.exists();
      if (kDebugMode) {
        print("Credentials file path: ${directory.path}");
        print("Credentials file exists: $exists");
      }

      if (!exists) {
        final grant = oauth2.AuthorizationCodeGrant(
          identifier,
          authorizationEndpoint,
          tokenEndpoint,
          secret: secret,
        );
        if (kDebugMode) {
          print("Created OAuth2 grant");
        }

        final authorizationUrl =
            grant.getAuthorizationUrl(redirectUrl, scopes: scopes);
        if (kDebugMode) {
          print("Authorization URL: $authorizationUrl");
        }

        if (await canLaunchUrl(authorizationUrl)) {
          await launchUrl(authorizationUrl);
          if (kDebugMode) {
            print("Launched URL for authorization");
          }

          // Listen for the redirect URI
          // This part depends on how your app can receive the redirect
          // For example, using a deep link or a custom URI scheme

          // Once you have the response, exchange the code for a token
          // You will need to handle this part based on your app's specific mechanism
          // Typically involves listening for the incoming URI, extracting the code, and exchanging it
        } else {
          throw 'Could not launch $authorizationUrl';
        }
      } else {
        // Loading existing credentials
        var credentials =
            oauth2.Credentials.fromJson(await credentialsFile.readAsString());
        client =
            oauth2.Client(credentials, identifier: identifier, secret: secret);
        if (kDebugMode) {
          print("OAuth2 client created from existing credentials");
        }
      }
    } catch (e) {
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

class OAuth2LoginResult {
  final OAuth2LoginStatus status;
  final String errorMessage;
  final oauth2.Credentials credential;

  OAuth2LoginResult(this.status, this.errorMessage, this.credential);
}

class GoogleSignInView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = '<platform-view-type>';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}
