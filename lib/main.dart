import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
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
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:video_player/video_player.dart';
import 'package:zmoney/loading_screen.dart';
import 'package:zmoney/ngrok.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

    FirebaseUIAuth.configureProviders([
      GoogleProvider(
          clientId:
              '446412900874-ifkm836l5ftprj362groq3q3gd5brq3c.apps.googleusercontent.com'),
      FacebookProvider(clientId: '939946717700321'),
    ]);

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
  GameAuth.signIn();
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // User is signed in
          return const LandingPage(); // Your main app screen if the user is already signed in
        } else {
          // User is not signed in, show the sign-in options
          return SignInScreen(
            // Email and password provider is included by default
            providers: [
              FacebookProvider(clientId: '939946717700321'),
              // Specify other providers here
              GoogleProvider(
                clientId:
                    'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com', // Use web client ID here
              ),
              // Add Facebook provider
            ],
            // Optionally, customize the SignInScreen further if needed
          );
        }
      },
    );
  }
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

class WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  User? currentUser;
  bool _isPasswordVisible = false;
  bool isSigningInWithGoogle = true; // Initially, try to sign in with Google
  bool showAlternativeOptions =
      false; // Show skip and OAuth2 only if Google sign-in fails
  oauth2.Client? client;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  static const _channel = MethodChannel('com.gg.zmoney/auth');
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<Map<String, dynamic>> _widgets = [];
  bool _isSignUpMode = true; // false for sign-in mode, true for sign-up mode

  final Map<String, Map<String, String>> oAuth2Providers = {
    'google': {
      'authorizationEndpoint': 'https://accounts.google.com/o/oauth2/v2/auth',
      'tokenEndpoint': 'https://oauth2.googleapis.com/token',
      'clientId': dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
      'redirectUri': dotenv.env['GOOGLE_REDIRECT_URI'] ?? '',
      'scopes': 'openid,profile,email',
    },
    'github': {
      'authorizationEndpoint': 'https://github.com/login/oauth/authorize',
      'tokenEndpoint': 'https://github.com/login/oauth/access_token',
      'clientId': dotenv.env['GITHUB_CLIENT_ID'] ?? '',
      'redirectUri': dotenv.env['GITHUB_REDIRECT_URI'] ?? '',
      'scopes': 'read:user,user:email',
    },
    // Add configurations for other providers...
  };

  @override
  void initState() {
    super.initState();
    _initWidgetsAndAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _closeKeyboard());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _revealWidgetsSequentially());
  }

  Widget _buildToggleFormModeButton() {
    Color textColor = _isSignUpMode
        ? Colors.yellowAccent
        : Colors.greenAccent; // Example colors
    return TextButton(
      onPressed: _toggleFormMode,
      child: Text(
        _isSignUpMode
            ? "Already have an account? Sign in here."
            : "Don't have an account? Register here.",
        style: TextStyle(color: textColor),
      ),
    );
  }

  void _toggleFormMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      // Reinitialize widgets to update according to the new mode
      _initWidgetsAndAnimations2();
    });
  }

  void _initWidgetsAndAnimations2() {
    _widgets = [
      {
        'widget': _buildEmailTextField(),
        'visible': true,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 200))
      },
      {
        'widget': _buildPasswordTextField(),
        'visible': true,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 200))
      },

      {
        'widget': _buildAuthActionButton(),
        'visible': true,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },

      {
        'widget': _buildSocialSignInButtons(), // The combined buttons widget
        'visible': true,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },

      {
        'widget': _buildToggleFormModeButton(),
        'visible': true,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },

      /* {
        'widget': _buildAuthGateButton(), // The new button
        'visible': true,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },*/

      // Add more buttons or elements as needed
    ];

    // Initialize the animation controllers
    for (var widgetData in _widgets) {
      widgetData['controller'].forward(from: 0.0);
    }
  }

  void _initWidgetsAndAnimations() {
    _widgets = [
      {
        'widget': _buildEmailTextField(),
        'visible': false,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },
      {
        'widget': _buildPasswordTextField(),
        'visible': false,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },

      {
        'widget': _buildAuthActionButton(),
        'visible': false,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },

      {
        'widget': _buildSocialSignInButtons(), // The combined buttons widget
        'visible': false,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },

      {
        'widget': _buildToggleFormModeButton(),
        'visible': false,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },
      /*   {
        'widget': _buildAuthGateButton(), // The new button
        'visible': false,
        'controller': AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500))
      },*/

      // Add more buttons or elements as needed
    ];

    // Initialize the animation controllers
    for (var widgetData in _widgets) {
      widgetData['controller'].forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBackgroundScreen(), // Use your animated background here
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _widgets.map<Widget>((element) {
                  // Wrap each widget with the animated widget builder
                  return AnimatedOpacity(
                    opacity: element['visible'] ? 1.0 : 0.0,
                    duration: (element['controller'] as AnimationController)
                        .duration!,
                    child: Transform.translate(
                      offset: element['visible']
                          ? Offset.zero
                          : const Offset(-100,
                              0), // Adjust this value to change starting position
                      child: element['widget'] as Widget,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSignInButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSignInButton(
          'Google',
          _signInWithGoogle,
          icon: FontAwesomeIcons.google,
          iconColor: Colors.blue, // Google color
        ),
        const SizedBox(width: 20), // Space between buttons
        _buildSignInButton(
          'GitHub',
          _signInWithGitHub,
          icon: FontAwesomeIcons.github,
          iconColor:
              Colors.white, // GitHub color, though default is already black
        ),
      ],
    );
  }

  Future<void> _signInWithGitHub() async {
    final providerConfig = oAuth2Providers['github'];
    if (providerConfig == null) {
      if (kDebugMode) {
        print('GitHub provider configuration not found');
      }
      return;
    }

    try {
      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          providerConfig['clientId']!,
          providerConfig['redirectUri']!,
          discoveryUrl: 'https://github.com/.well-known/openid-configuration',
          scopes: ['read:user', 'user:email'],
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: providerConfig['authorizationEndpoint']!,
            tokenEndpoint: providerConfig['tokenEndpoint']!,
          ),
        ),
      );

      if (result != null) {
        // Use the access token to sign in with Firebase
        final AuthCredential credential =
            GithubAuthProvider.credential(result.accessToken!);

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        if (kDebugMode) {
          print("GitHub Sign-In successful: ${userCredential.user}");
        }

        // Optionally, navigate or update UI state here
      } else {
        if (kDebugMode) {
          print("GitHub Sign-In aborted by user");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('GitHub Sign-In failed: $e');
      }
    }
  }

  Widget _buildAuthActionButton() {
    Color buttonColor =
        _isSignUpMode ? Colors.blueAccent : Colors.lightGreen; // Example colors
    // Define the vertical padding value
    double verticalPadding = 8.0;
    return Padding(
      padding: EdgeInsets.only(
          top: verticalPadding,
          bottom: verticalPadding), // Apply external padding
      child: ElevatedButton.icon(
        icon: Icon(
          _isSignUpMode
              ? FontAwesomeIcons.userPlus
              : FontAwesomeIcons.rightFromBracket,
          size: 24,
        ),
        label: Text(_isSignUpMode ? 'Sign Up' : 'Sign In'),
        onPressed: _isSignUpMode ? _handleSignUp : _handleSignIn,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: buttonColor, // Icon and text color
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10), // Internal padding around the icon and text
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(30), // Rounded corners for the button
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAuthGateButton() {
    return ElevatedButton.icon(
      icon: const Icon(
        FontAwesomeIcons.doorOpen, // Example icon
        size: 24,
      ),
      label: const Text('Go to Auth Gate'),
      onPressed: () => _navigateToWidgetAuthGate(context),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  void _navigateToWidgetAuthGate(BuildContext context) {
    // Assuming WidgetAuthGate is another widget that handles authentication
    // Replace 'WidgetAuthGate()' with your actual WidgetAuthGate constructor
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  Widget _buildEmailTextField() {
    Color borderColor =
        _isSignUpMode ? Colors.yellowAccent : Colors.greenAccent;
    return TextField(
      key: ValueKey(
          _isSignUpMode), // This forces the widget to rebuild on toggle
      controller: _emailController,
      decoration: InputDecoration(
        labelText: '',
        hintText: 'Enter your email',
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: borderColor.withOpacity(0.5), width: 1.0),
        ),
        prefixIcon: const Icon(Icons.email),
        filled: true, // Enable background color fill
        fillColor: Colors.white.withOpacity(0.5), // Semi-transparent white
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordTextField() {
    Color borderColor =
        _isSignUpMode ? Colors.yellowAccent : Colors.greenAccent;
    return TextField(
      key: ValueKey(
          _isSignUpMode), // This forces the widget to rebuild on toggle
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: '',
        hintText: 'Enter your password',
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: borderColor.withOpacity(0.5), width: 1.0),
        ),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true, // Enable background color fill
        fillColor: Colors.white.withOpacity(0.5), // Semi-transparent white
      ),
      obscureText: !_isPasswordVisible,
    );
  }

  void _revealWidgetsSequentially() async {
    for (int i = 0; i < _widgets.length; i++) {
      final widgetData = _widgets[i];
      final controller = widgetData['controller'] as AnimationController;
      await Future.delayed(
          const Duration(milliseconds: 500)); // Adjust delay as needed
      setState(() {
        widgetData['visible'] = true;
      });
      controller.forward();
    }
  }

  Future<bool> _signUp(String email, String password) async {
    try {
      final bool result = await _channel.invokeMethod('signUp', {
        'email': email,
        'password': password,
      });
      if (result) {
        _showSnackBar("Sign-up successful. Please verify your email.");
      }
      return result;
    } on PlatformException catch (e) {
      _showSnackBar(
          _getErrorMessage(e.code)); // Use snack bar for error messages
      return false;
    }
  }

  Future<bool> _signIn(String email, String password) async {
    try {
      final bool result = await _channel.invokeMethod('signIn', {
        'email': email,
        'password': password,
      });
      return result;
    } on PlatformException catch (e) {
      _showSnackBar(_getSignInErrorMessage(e.code));
      return false;
    }
  }

  Widget _buildSignInButton(String providerName, VoidCallback onPressed,
      {required IconData icon,
      Color? iconColor,
      double iconSize = 24.0,
      double verticalPadding = 8.0}) {
    // Added verticalPadding parameter for external padding customization
    return Padding(
      padding: EdgeInsets.only(
          top: verticalPadding, bottom: verticalPadding), // External padding
      child: ElevatedButton.icon(
        icon: Icon(
          icon,
          color: Colors
              .white, // Assuming you always want the icon color to be white
          size: iconSize, // Icon size
        ),
        label: Text(
          "Sign in with $providerName",
          style: const TextStyle(
            fontSize: 12,
            color: /*iconColor ??*/ Colors.white, // Icon color
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue, // This affects the text color
          padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10), // Internal padding around the icon and text
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(30), // Rounded corners for the button
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        // Assuming _signUp() interacts with Firebase or another auth service
        final bool success = await _signUp(email, password);
        if (success) {
          _showSnackBar("Sign-up successful. Please verify your email.");
          // Optionally navigate to a different screen or change UI state
        }
      } on PlatformException catch (e) {
        _showSnackBar(_getErrorMessage(e.code));
      }
    } else {
      _showSnackBar("Email and password cannot be empty.");
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials. Sign in using a provider associated with this email address.';
      case 'auth-domain-config-required':
        return 'Authentication domain configuration is required.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please enable it in the Firebase Console.';
      case 'user-disabled':
        return 'The user account has been disabled by an administrator.';
      case 'user-not-found':
        return 'No user found for the provided email.';
      case 'wrong-password':
        return 'Wrong password provided for the email.';
      case 'too-many-requests':
        return 'Too many attempts to sign in as this user. Please try again later.';
      case 'operation-not-supported-in-this-environment':
        return 'This operation is not supported in the environment this application is running on. "location.protocol" must be http, https or chrome-extension and web storage must be enabled.';
      case 'timeout':
        return 'The operation has timed out. Please try again.';
      case 'missing-android-pkg-name':
        return 'An Android Package Name must be provided if the Android App is required to be installed.';
      case 'missing-continue-uri':
        return 'A continue URL must be provided in the request.';
      case 'missing-ios-bundle-id':
        return 'An iOS Bundle ID must be provided if an App Store ID is provided.';
      case 'invalid-continue-uri':
        return 'The continue URL provided in the request is invalid.';
      case 'unauthorized-continue-uri':
        return 'The domain of the continue URL is not whitelisted. Please whitelist the domain in the Firebase console.';
      // Add more cases as needed
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _getSignInErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'user-disabled':
        return 'The user account has been disabled by an administrator.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      // Include additional error handling as needed
      default:
        return 'An error occurred during sign-in. Please try again.';
    }
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      final success = await _signIn(email, password);
      if (success) {
        _showSnackBar("Sign-in successful.");
        // Navigate to the next screen or show success message
      } else {
        // Error message is shown via _signIn method
      }
    } else {
      _showSnackBar("Email and password cannot be empty.");
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      final bool result = await _channel.invokeMethod('signUp', {
        'email': email,
        'password': password,
      });
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to sign up: ${e.message}");
      }
      return false;
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _signInWithOAuth2(String providerKey) async {
    try {
      final providerConfig = oAuth2Providers[providerKey];
      if (providerConfig == null) {
        print('Provider configuration not found');
        return;
      }

      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          providerConfig['clientId']!,
          providerConfig['redirectUri']!,
          scopes: providerConfig['scopes']!.split(','),
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: providerConfig['authorizationEndpoint']!,
            tokenEndpoint: providerConfig['tokenEndpoint']!,
          ),
        ),
      );

      if (result != null) {
        // Simulate retrieving email from the OAuth provider's user info endpoint
        // This is a placeholder and should be replaced with actual logic
        final email = ""; // Placeholder
        final response = await approachMasterEndpoint(
            email, result.idToken ?? '', result.accessToken ?? '');

        if (response.statusCode == 200) {
          // Handle response, save JWT token, retrieve player data, navigate
          _handleSuccessfulSignIn(response);
        } else {
          print("Error contacting master endpoint: ${response.statusCode}");
          // Handle error in contacting master endpoint
        }
      } else {
        print("OAuth2 authorization failed");
        // Handle failed authorization
      }
    } catch (e) {
      print('Error during OAuth2 Sign-In: $e');
      // Handle sign-in error
    }
  }

  void _handleSuccessfulSignIn(http.Response response) async {
    // Parse response, save JWT token, retrieve player data, navigate
    var responseData = jsonDecode(response.body);
    var jwtToken = responseData['token'];
    await secureStorage.write(key: 'jwtToken', value: jwtToken);

    final playerDataResponse = await verifyAndRetrieveData(jwtToken);
    if (playerDataResponse.statusCode == 200) {
      var playerData = jsonDecode(playerDataResponse.body)['playerData'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('playerData', jsonEncode(playerData));

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LandingPage()));
    } else {
      print(
          "Error verifying token and retrieving data: ${playerDataResponse.statusCode}");
      // Handle error in player data retrieval
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
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
        child: const Text(
            'You should probably login, as it might be hard to later cash your winnings. But you can help friends to penetrate the number and skip the login here'),
      ),
    );
  }
}

class AnimatedBackgroundScreen extends StatefulWidget {
  @override
  _AnimatedBackgroundScreenState createState() =>
      _AnimatedBackgroundScreenState();
}

class _AnimatedBackgroundScreenState extends State<AnimatedBackgroundScreen>
    with TickerProviderStateMixin {
  late AnimationController _imageSwitchController;
  late AnimationController
      _imageMoveController; // Controller for moving the second image
  late Animation<Offset>
      _backgroundOffsetAnimation; // Animation for moving the second image
  late Animation<double> _fadeAnimation1;
  late Animation<double> _fadeAnimation2;
  late VideoPlayerController _videoController; // Controller for the video

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.network(
      // 'https://video-previews.elements.envatousercontent.com/files/92826da3-9606-49ad-8d4e-8412d4fdd21a/video_preview_h264.mp4'
      'https://assets.mixkit.co/videos/preview/mixkit-stock-market-exchange-and-forex-prices-background-47006-large.mp4', // Direct video file URL
      //'http://www.zahasmaster.pro/video/main.mp4'
      //'https://www.zahasmaster.pro/video/main2.mp4'
    )..initialize().then((_) {
        setState(
            () {}); // Ensure the video player is reloaded once the video is initialized
      });
    _videoController.setLooping(true); // If you want the video to loop
    _videoController.play(); // Auto-play the video

    // Controller for switching between the images
    _imageSwitchController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..forward(); // Start the animation to fade to the second image

    // Initialize _imageMoveController without repeat
    _imageMoveController = AnimationController(
      duration: const Duration(
          seconds: 30), // Adjusted duration for each movement cycle
      vsync: this,
    );

    // Initial movement setup
    _initMoveAnimation();

    // Listen for the end of an animation cycle to change direction
    _imageMoveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _changeDirection();
      }
    });

    // Start the move animation
    _imageMoveController.forward();

    // Fade animations for transitioning between the two images
    _fadeAnimation1 = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _imageSwitchController, curve: Curves.easeInOut),
    );
    _fadeAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageSwitchController, curve: Curves.easeInOut),
    );
  }

  void _initMoveAnimation() {
    _backgroundOffsetAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0.0),
      end: const Offset(0.2, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _imageMoveController,
        curve: Curves.linear,
      ),
    );
  }

  void _changeDirection() {
    // Capture the current offset of the animation
    final Offset currentOffset = _backgroundOffsetAnimation.value;

    // Generate new random end points within certain constraints
    double xEnd = -0.2 + Random().nextDouble() * 0.4;
    double yEnd = -0.1 + Random().nextDouble() * 0.2;

    // Ensure the new direction is somewhat different to make the movement noticeable
    // but starts from the current position
    _imageMoveController.reset();
    _backgroundOffsetAnimation = Tween<Offset>(
      begin: currentOffset, // Start from current position
      end: Offset(xEnd, yEnd), // New random position
    ).animate(
      CurvedAnimation(
        parent: _imageMoveController,
        curve: Curves.linear, // Using a linear curve for consistent movement
      ),
    );

    // Restart the animation from the new current position to the new random position
    _imageMoveController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnimation1,
          child: Image.asset(
            'assets/mainscreen.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        FadeTransition(
          opacity: _fadeAnimation2,
          child: AnimatedBuilder(
            animation: _backgroundOffsetAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.6,
                child: SlideTransition(
                  position: _backgroundOffsetAnimation,
                  child: VideoPlayer(
                      _videoController), // Updated to use VideoPlayer
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _imageSwitchController.dispose();
    _imageMoveController.dispose();
    super.dispose();
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
