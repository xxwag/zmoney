import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'landing_page.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  User? currentUser;
  bool showSkipButton = true; // Initially show the skip button

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In was cancelled.");
        return;
      }

      final GoogleSignInAuthentication? googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      print("Signed in as: ${userCredential.user?.email}");

      setState(() {
        currentUser = userCredential.user;
        showSkipButton = false;
      });
    } catch (error) {
      print('Error during Google Sign-In: $error');
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
    return SizedBox.shrink(); // Empty widget if no user
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        child: const Text('Skip'),
      ),
    );
  }

  Widget _buildProceedButton() {
    return Visibility(
      visible: currentUser != null,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        child: const Text('Proceed'),
      ),
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
            if (showSkipButton) _buildSkipButton(),
          ],
        ),
      ),
    );
  }
}
