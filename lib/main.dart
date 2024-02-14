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
import 'package:path_provider/path_provider.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:zmoney/loading_screen.dart';
import 'package:zmoney/ngrok.dart';

import 'landing_page.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await clearSharedPreferences();

  String envFileName = ".env";
  await dotenv.load(fileName: envFileName);

  const secureStorage = FlutterSecureStorage();
  await secureStorage.write(
      key: 'ngrokToken', value: dotenv.env['NGROK_TOKEN']);
  // Fetch Ngrok data
  await NgrokManager.fetchNgrokData();

  // Start with LoadingScreen
  Widget homeScreen = const LoadingScreen();
  runApp(MyApp(homeScreen: homeScreen));

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await MobileAds.instance.initialize();

    String? jwtToken = await secureStorage.read(key: 'jwtToken');
    if (jwtToken != null) {
      final playerDataResponse = await verifyAndRetrieveData(jwtToken);
      if (playerDataResponse.statusCode == 200) {
        var playerData = jsonDecode(playerDataResponse.body)['playerData'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('playerData', jsonEncode(playerData));

        // homeScreen = const LandingPage();
        homeScreen = const LandingPage();
      } else {
        homeScreen = const WelcomeScreen();
      }
    } else {
      homeScreen = const WelcomeScreen();
    }
  } else {
    homeScreen = const WelcomeScreen();
  }
  await GameAuth.signIn();
  Future.delayed(const Duration(seconds: 3), () {
    runApp(MyApp(homeScreen: homeScreen));
  });
}

Future<http.Response> verifyAndRetrieveData(String jwtToken) async {
  // Print the JWT token for verification
  if (kDebugMode) {
    print("Verifying with JWT token: $jwtToken");
  }

  return http.post(
    Uri.parse('${NgrokManager.ngrokUrl}/api/verifyAndRetrieveData'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': jwtToken}),
  );
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
  bool isSigningInWithGoogle = true; // Initially, try to sign in with Google
  bool showAlternativeOptions =
      false; // Show skip and OAuth2 only if Google sign-in fails
  oauth2.Client? client;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeKeyboard();
      _signInWithGoogle(); // Try to sign in with Google immediately
    });
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _signInWithOAuth2();
        if (kDebugMode) print("Google Sign-In was cancelled.");
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
        final response = await approachMasterEndpoint(
          userCredential.user!.email!,
          googleAuth.idToken!,
          googleAuth.accessToken!,
        );

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          var jwtToken = responseData['token'];
          await secureStorage.write(key: 'jwtToken', value: jwtToken);

          final playerDataResponse = await verifyAndRetrieveData(jwtToken);
          if (playerDataResponse.statusCode == 200) {
            var playerData = jsonDecode(playerDataResponse.body)['playerData'];
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('playerData', jsonEncode(playerData));

            if (kDebugMode) {
              print("Retrieved Player Data: $playerData");
            }

            // Navigate to the next screen or update the state as necessary
            // Example: Navigate to the LandingPage
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LandingPage()));
          } else {
            if (kDebugMode) {
              print(
                  "Error verifying token and retrieving data: ${playerDataResponse.statusCode}");
            }
            // Handle error in player data retrieval
          }
        } else {
          if (kDebugMode) {
            print("Error contacting master endpoint: ${response.statusCode}");
          }
          // Handle error in contacting master endpoint
        }
      } else {
        if (kDebugMode) {
          print("UserCredential user is null, authentication failed");
        }
        // Handle authentication failure
      }
    } catch (error) {
      if (kDebugMode) print('Error during Google Sign-In: $error');
      // Handle general sign-in error
    }
  }

  Future<http.Response> approachMasterEndpoint(
      String email, String idToken, String accessToken) async {
    return http.post(
      Uri.parse('${NgrokManager.ngrokUrl}/api/masterEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'idToken': idToken,
        'accessToken': accessToken,
      }),
    );
  }

  Future<http.Response> verifyAndRetrieveData(String jwtToken) async {
    // Print the JWT token for verification
    if (kDebugMode) {
      print("Verifying with JWT token: $jwtToken");
    }

    return http.post(
      Uri.parse('${NgrokManager.ngrokUrl}/api/verifyAndRetrieveData'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': jwtToken}),
    );
  }

  Future<void> _signInWithOAuth2() async {
    try {
      // Debug print to indicate the start of the OAuth2 process
      if (kDebugMode) {
        print("Starting OAuth2 sign-in process");
      }

      // ignore: unused_local_variable
      final authorizationEndpoint =
          Uri.parse('http://example.com/oauth2/authorization');
      // ignore: unused_local_variable
      final tokenEndpoint = Uri.parse('http://example.com/oauth2/token');
      // ignore: unused_local_variable
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
        _warnUserAboutAccountIssues();
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
        _warnUserAboutAccountIssues();
      }
    } catch (e) {
      // Log the error
      if (kDebugMode) {
        print('Error during OAuth2 Sign-In: $e');
      }
      _warnUserAboutAccountIssues();
    }
  }

  Future<void> _warnUserAboutAccountIssues() async {
    // Show warning dialog to the user
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sign-In Failed'),
          content: const Text(
              'Your game account might not work, and your game data might not be stored. '
              'We might not be able to authorize your winnings or withdrawals later on.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Understand'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                );
              },
            ),
          ],
        );
      },
    );
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
        title: const Text('How Much? Signup'),
      ),
      body: Center(
        child: isSigningInWithGoogle
            ? const CircularProgressIndicator() // Show loading indicator while trying to sign in with Google
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showAlternativeOptions) ...[
                    // Use showAlternativeOptions here
                    _buildOAuth2SignInButton(),
                    _buildSkipButton(),
                  ],
                ],
              ),
      ),
    );
  }

  // Add the missing _buildSkipButton method here
  Widget _buildSkipButton() {
    return Visibility(
      visible:
          showAlternativeOptions, // Only show if alternative options should be displayed
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        child: const Text('Skip'),
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
  const GoogleSignInView({super.key});

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
