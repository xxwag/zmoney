import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'landing_page.dart';

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
        showSkipButton = false;

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
      print("Starting OAuth2 sign-in process");

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
      print("Credentials file exists: $exists");

      if (exists) {
        var credentials =
            oauth2.Credentials.fromJson(await credentialsFile.readAsString());
        client =
            oauth2.Client(credentials, identifier: identifier, secret: secret);
        print("OAuth2 client created from existing credentials");
      } else {
        // Logic to handle OAuth2 authorization flow
        print(
            "No existing credentials found, need to start authorization flow");
        // Implement the logic to complete the authorization flow
      }

      if (client != null) {
        print("OAuth2 client is available, saving credentials");
        await credentialsFile.writeAsString(client!.credentials.toJson());
      } else {
        print("OAuth2 client is null, unable to save credentials");
      }
    } catch (e) {
      // Log the error
      print('Error during OAuth2 Sign-In: $e');
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
        title: const Text('Welcome to App Lottery'),
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
