import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

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
import 'package:zmoney/fukk_widgets/app_assets.dart';

import 'package:zmoney/fukk_widgets/language_selector.dart';
import 'package:zmoney/fukk_widgets/translator.dart';
import 'package:zmoney/loading_screen.dart';
import 'package:zmoney/ngrok.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'landing_page.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';
import 'package:auto_localization/auto_localization.dart';

final translator =
    Translator(currentLanguage: 'en'); // Set initial language as needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GamesServices.signIn();
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

    await FirebaseAppCheck.instance
        .activate(androidProvider: AndroidProvider.playIntegrity);

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

  Future.delayed(const Duration(seconds: 3), () {
    runApp(MyApp(homeScreen: homeScreen));
  });
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
              // FacebookProvider(clientId: '939946717700321'),
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
  bool _isPasswordValid = false; // New state variable
  bool isSigningInWithGoogle = true; // Initially, try to sign in with Google
  bool showAlternativeOptions =
      false; // Show skip and OAuth2 only if Google sign-in fails
  oauth2.Client? client;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  static const _channel = MethodChannel('com.gg.zmoney/auth');

  List<Map<String, dynamic>> _widgets = [];
  bool _isSignUpMode = true; // false for sign-in mode, true for sign-up mode
  bool _isAuthenticating = false; // New variable to track authentication state

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
    _passwordController.addListener(_updatePasswordValidity);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildToggleFormModeButton() {
    // Define the keys for the translations
    const String signInKey = "Already have an account? Sign in here.";
    const String signUpKey = "Don't have an account? Register here.";

    // Determine the current key based on the sign-up mode
    final String currentKey = _isSignUpMode ? signInKey : signUpKey;

    Color textColor = _isSignUpMode ? Colors.yellowAccent : Colors.greenAccent;

    return FutureBuilder<String>(
      future: translator
          .translate(currentKey), // Fetch the translation asynchronously
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        // Check if the translation is loaded
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          // Translation is loaded, use it
          return TextButton(
            onPressed: _toggleFormMode,
            child: Text(
              snapshot.data!, // Use the translated text
              style: TextStyle(color: textColor),
            ),
          );
        } else {
          // Translation is not yet loaded or an error occurred, show a placeholder or error message
          return const CircularProgressIndicator(); // Or some other placeholder widget
        }
      },
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
          AnimatedBackgroundScreen(),
          Positioned(
            top: 35, // Adjust as needed
            right: 20, // Adjust as needed
            child: LanguageSelectorWidget(
              onLanguageChanged: (String newLanguageCode) {
                _initWidgetsAndAnimations2(); // Re-initialize widgets and animations
              },
              dropdownColor: Colors
                  .transparent, // Example color for the dropdown background
              textColor: Colors.white, // Example color for the text
              iconColor: Colors.white, // Example color for the dropdown icon
              underlineColor: Colors.white, // Example color for the underline
            ),
          ),
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
    // Define the keys for the translations
    const String googleKey = "Sign in with Google";
    const String githubKey = "Sign in with GitHub";

    return Center(
      // Use Center to keep the Wrap widget centered on the screen
      child: Wrap(
        alignment: WrapAlignment.center, // Center the buttons horizontally
        spacing: 20, // Space between buttons horizontally
        runSpacing: 20, // Space between buttons when wrapped to the next line
        children: [
          FutureBuilder<String>(
            future: translator.translate(
                googleKey), // Fetch the translation asynchronously for Google
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return _buildSignInButton(
                  snapshot.data!, // Use the translated text
                  _signInWithGoogle,
                  icon: FontAwesomeIcons.google,
                  iconColor: Colors.blue, // Google color
                );
              } else {
                return const CircularProgressIndicator(); // Or some other placeholder widget
              }
            },
          ),
          FutureBuilder<String>(
            future: translator.translate(
                githubKey), // Fetch the translation asynchronously for GitHub
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return _buildSignInButton(
                  snapshot.data!, // Use the translated text
                  _signInWithGitHub,
                  icon: FontAwesomeIcons.github,
                  iconColor: Colors
                      .white, // GitHub color, though default is already black
                );
              } else {
                return const CircularProgressIndicator(); // Or some other placeholder widget
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuthActionButton() {
    bool isButtonDisabled = _isAuthenticating;
    Color buttonColor = _isSignUpMode ? Colors.blueAccent : Colors.lightGreen;

    // Define keys for the translations
    const String signUpKey = "Sign Up";
    const String signInKey = "Sign In";

    // Determine the current action text based on the sign-up mode
    final String currentActionKey = _isSignUpMode ? signUpKey : signInKey;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8.0), // Apply external padding
      child: FutureBuilder<String>(
        future: translator.translate(
            currentActionKey), // Fetch the translation asynchronously
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            // Translation is loaded, use it
            return ElevatedButton.icon(
              icon: Icon(
                _isSignUpMode
                    ? FontAwesomeIcons.userPlus
                    : FontAwesomeIcons.rightFromBracket,
                size: 24,
              ),
              label: Text(snapshot.data!), // Use the translated text
              onPressed: isButtonDisabled
                  ? null
                  : (_isSignUpMode ? _handleSignUp : _handleSignIn),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: buttonColor, // Icon and text color
                minimumSize: const Size(double.infinity, 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      30), // Rounded corners for the button
                ),
              ),
            );
          } else {
            // Translation is not yet loaded or an error occurred, show a placeholder or error message
            return const CircularProgressIndicator(); // Or some other placeholder widget
          }
        },
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

  Widget _buildEmailTextField() {
    Color borderColor =
        _isSignUpMode ? Colors.yellowAccent : Colors.greenAccent;

    return FutureBuilder<String>(
      // Asynchronously fetch the translated text
      future: translator.translate('Enter your email'),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        // Determine the text to display: either the translation or a default/fallback text
        String displayText =
            snapshot.hasData ? snapshot.data! : 'Enter your email';

        return TextField(
          key: ValueKey(
              _isSignUpMode), // This forces the widget to rebuild on toggle
          controller: _emailController,
          decoration: InputDecoration(
            labelText: '',
            hintText: displayText, // Use the translated or fallback text
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: borderColor.withOpacity(0.5), width: 1.0),
            ),
            prefixIcon: const Icon(Icons.email),
            filled: true,
            fillColor: Colors.white.withOpacity(0.5),
          ),
          keyboardType: TextInputType.emailAddress,
        );
      },
    );
  }

  void _updatePasswordValidity() {
    final password = _passwordController.text;
    // Update the state based on password validity
    final isValid = _validatePassword(password) ==
        null; // Reuse your existing validation logic
    setState(() {
      _isPasswordValid = isValid;
      _initWidgetsAndAnimations2();
    });
  }

  Widget _buildPasswordTextField() {
    Color borderColor =
        _isSignUpMode ? Colors.yellowAccent : Colors.greenAccent;

    // Translate the hints for password fields
    const String passwordHintKey = 'Choose a strong password';
    const String confirmPasswordHintKey = 'Confirm your password';

    // Translate the error message for the confirm password field
    const String confirmPasswordErrorKey = 'Passwords do not match';

    Widget passwordField = FutureBuilder<String>(
      future: translator.translate(passwordHintKey),
      builder: (context, snapshot) {
        return TextFormField(
          key: const ValueKey('password'),
          controller: _passwordController,
          decoration: _buildInputDecoration(
              snapshot.hasData ? snapshot.data! : '', borderColor),
          obscureText: !_isPasswordVisible,
          validator: _validatePassword,
        );
      },
    );

    Widget confirmPasswordField = _isSignUpMode && _isPasswordValid
        ? FutureBuilder<List<String>>(
            future: Future.wait([
              translator.translate(confirmPasswordHintKey),
              translator.translate(confirmPasswordErrorKey),
            ]),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return TextFormField(
                  key: const ValueKey('confirmPassword'),
                  controller: _confirmPasswordController,
                  decoration:
                      _buildInputDecoration(snapshot.data![0], borderColor),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return snapshot
                          .data![1]; // 'Passwords do not match' error message
                    }
                    return null;
                  },
                );
              } else {
                return const CircularProgressIndicator(); // Loading indicator or placeholder
              }
            },
          )
        : Container();

    return Column(
      children: [
        passwordField,
        if (_isSignUpMode && _isPasswordValid) const SizedBox(height: 10),
        if (_isSignUpMode && _isPasswordValid) confirmPasswordField,
      ],
    );
  }

// Validator method for the password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password'; // Ensures a password is entered
    }
    if (!RegExp(r'^(?=.*[A-Z]).+$').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter'; // Checks for uppercase letter
    }
    if (!RegExp(r'^(?=.*\d).+$').hasMatch(value)) {
      return 'Password must contain at least one number'; // Checks for digit
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long'; // Checks for length
    }
    return null; // Returns null if the input passes all validations
  }

//// Helper method to build input decoration with a functional visibility toggle
  InputDecoration _buildInputDecoration(String hintText, Color borderColor) {
    return InputDecoration(
      labelText: '',
      hintText: hintText,
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor.withOpacity(0.5), width: 1.0),
      ),
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: IconButton(
        icon:
            Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
        onPressed: () {
          setState(() {
            // Toggle the password visibility
            _isPasswordVisible = !_isPasswordVisible;
            _initWidgetsAndAnimations2();
          });
        },
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
    );
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticating = true; // Lock UI
      try {
        // Attempt to sign up the user with the provided credentials
        final bool signUpSuccess = await _signUp(email, password);
        if (signUpSuccess) {
          // Sign-up successful, now sign in the user automatically with the same credentials
          final bool signInSuccess = await _signIn(email, password);
          if (signInSuccess) {
            // Sign-in was successful, navigate to the next screen or update UI state as needed
            await _showSnackBar("Sign-up and sign-in successful.");
            // For example, navigate to a home screen: Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
          } else {
            // Handle sign-in failure if necessary
            await _showSnackBar(
                "Sign-up successful, but sign-in failed. Please try to sign in.");
          }
        } else {
          // Handle sign-up failure
          await _showSnackBar("Sign-up failed. Please try again.");
        }
      } on PlatformException catch (e) {
        await _showSnackBar(
            _getErrorMessage(e.code)); // Use snack bar for error messages
      } finally {
        _isAuthenticating = false; // Unlock UI
      }
    } else {
      await _showSnackBar("Email and password cannot be empty.");
    }
  }

  Future<bool> _signIn(String email, String password) async {
    _isAuthenticating = true; // Lock UI
    bool signInSuccess = false;
    try {
      final Map<dynamic, dynamic> authDetails =
          await _channel.invokeMethod('signIn', {
        'email': email,
        'password': password,
      });

      // Extract email, ID token, and Firebase user ID (as accessToken) from authDetails
      final String? returnedEmail = authDetails['email'];
      final String? idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      final String? firebaseUserId =
          authDetails['accessToken']; // Firebase user ID is used as accessToken

      if (returnedEmail != null && idToken != null && firebaseUserId != null) {
        // Use the returned credentials to approach the master endpoint
        final response = await approachMasterEndpoint(
            returnedEmail, idToken, firebaseUserId,
            isFirebaseId: true);

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          var jwtToken = responseData['token'];
          await secureStorage.write(key: 'jwtToken', value: jwtToken);

          final playerDataResponse = await verifyAndRetrieveData(jwtToken);
          if (playerDataResponse.statusCode == 200) {
            var playerData = jsonDecode(playerDataResponse.body)['playerData'];
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('playerData', jsonEncode(playerData));
            if (context.mounted) {
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LandingPage()));

              await _showSnackBar("Sign-in successful.");
              signInSuccess = true;
            }
          } else {
            await _showSnackBar("Error verifying token and retrieving data.");
          }
        } else {
          await _showSnackBar("Error contacting master endpoint.");
        }
      } else {
        await _showSnackBar("Authentication failed.");
      }
    } catch (error) {
      await _showSnackBar("error_during_signin:$error");
    } finally {
      _isAuthenticating = false; // Unlock UI
    }
    return signInSuccess;
  }

  Future<http.Response> approachMasterEndpoint(
      String email, String idToken, String token,
      {bool isFirebaseId = false}) async {
    return http.post(
      Uri.parse('${NgrokManager.ngrokUrl}/api/masterEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'idToken': idToken,
        'token':
            token, // Use a generic name like 'token' for both Firebase user ID and Google access token
        'isFirebaseId':
            isFirebaseId, // Indicates the type of token being passed
      }),
    );
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      final success = await _signIn(email, password);
      if (success) {
        // If _signIn is successful, additional navigation or success handling can be performed here

        // _showSnackBar("Sign-in successful."); is already called within _signIn
      } else {
        // Error message handling is already done within _signIn
      }
    } else {
      await _showSnackBar("Email and password cannot be empty.");
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
          providerName,
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

  Future<void> _signInWithGoogle() async {
    _isAuthenticating = true; // Lock UI
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        await _showSnackBar("Google Sign-In was cancelled.");
        _isAuthenticating = false; // Unlock UI
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
          isFirebaseId: false,
        );

        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          var jwtToken = responseData['token'];
          await secureStorage.write(key: 'jwtToken', value: jwtToken);
          if (context.mounted) {
            final playerDataResponse = await verifyAndRetrieveData(jwtToken);
            if (playerDataResponse.statusCode == 200) {
              var playerData =
                  jsonDecode(playerDataResponse.body)['playerData'];
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('playerData', jsonEncode(playerData));

              // Navig if (context.mounted) {ate to the next screen or update the state as necessary
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LandingPage()));
              await _showSnackBar("Sign-in successful.");
            }
          } else {
            await _showSnackBar("Error verifying token and retrieving data.");
            _isAuthenticating = false; // Unlock UI
          }
        } else {
          await _showSnackBar("Error contacting master endpoint.");
          _isAuthenticating = false; // Unlock UI
        }
      } else {
        await _showSnackBar("Authentication failed.");
        _isAuthenticating = false; // Unlock UI
      }
    } catch (error) {
      await _showSnackBar('Error during Google Sign-In: $error');
      _isAuthenticating = false; // Unlock UI
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

  Future<void> _showSnackBar(String messageKey) async {
    // Assuming you have a method to translate messages based on a key
    final String message = await translator.translate(messageKey);

    // After the async gap, check if the widget is still mounted before using `context`
    if (mounted) {
      final snackBar = SnackBar(content: Text(message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<bool> _signUp(String email, String password) async {
    try {
      final bool result = await _channel.invokeMethod('signUp', {
        'email': email,
        'password': password,
      });
      if (result) {
        await _showSnackBar("signup_successful_verify_email");
      }
      return result;
    } on PlatformException catch (e) {
      await _showSnackBar(
          e.code); // Assuming your error messages are also translated
      return false;
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _signInWithGitHub() async {
    _isAuthenticating = true; // Lock UI
    final providerConfig = oAuth2Providers['github'];
    if (providerConfig == null) {
      await _showSnackBar('GitHub provider configuration not found');
      _isAuthenticating = false; // Unlock UI
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
        final AuthCredential credential =
            GithubAuthProvider.credential(result.accessToken!);
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          // Assuming your backend needs email, GitHub access token, and possibly a Firebase token
          String? firebaseToken = await userCredential.user!.getIdToken(true);
          final response = await approachMasterEndpoint(
            userCredential.user!.email!,
            firebaseToken!, // Assuming the firebaseToken is not null, handle nullability as needed
            result.accessToken!, // GitHub access token
          );

          if (response.statusCode == 200) {
            var responseData = jsonDecode(response.body);
            var jwtToken = responseData['token'];
            await secureStorage.write(key: 'jwtToken', value: jwtToken);

            final playerDataResponse = await verifyAndRetrieveData(jwtToken);
            if (playerDataResponse.statusCode == 200) {
              var playerData =
                  jsonDecode(playerDataResponse.body)['playerData'];
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('playerData', jsonEncode(playerData));

              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                );
              }
              await _showSnackBar("GitHub Sign-in successful.");
            } else {
              await _showSnackBar("Error verifying token and retrieving data.");
              _isAuthenticating = false; // Unlock UI
            }
          } else {
            await _showSnackBar("Error contacting master endpoint.");
            _isAuthenticating = false; // Unlock UI
          }
        } else {
          await _showSnackBar("Authentication failed.");
          _isAuthenticating = false; // Unlock UI
        }
      } else {
        await _showSnackBar("GitHub Sign-In aborted by user.");
        _isAuthenticating = false; // Unlock UI
      }
    } catch (e) {
      await _showSnackBar('GitHub Sign-In failed: $e');
      _isAuthenticating = false; // Unlock UI
    }
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

  // Add the missing _buildSkipButton method here
  // ignore: unused_element
  Widget _buildSkipButton() {
    // Define the key for the translation
    const String skipButtonKey =
        "You should probably login, as it might be hard to later cash your winnings. But you can help friends to penetrate the number and skip the login here";

    return Visibility(
      visible:
          showAlternativeOptions, // Only show if alternative options should be displayed
      child: FutureBuilder<String>(
        future: translator
            .translate(skipButtonKey), // Fetch the translation asynchronously
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          // Check if the translation is loaded
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            // Translation is loaded, use it
            return TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                );
              },
              child: Text(
                snapshot.data!, // Use the translated text
              ),
            );
          } else {
            // Translation is not yet loaded or an error occurred, show a placeholder or error message
            return const CircularProgressIndicator(); // Or some other placeholder widget
          }
        },
      ),
    );
  }
}

class AnimatedBackgroundScreen extends StatefulWidget {
  const AnimatedBackgroundScreen({super.key});

  @override
  AnimatedBackgroundScreenState createState() =>
      AnimatedBackgroundScreenState();
}

class AnimatedBackgroundScreenState extends State<AnimatedBackgroundScreen>
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

    _videoController = VideoPlayerController.networkUrl(
      // 'https://video-previews.elements.envatousercontent.com/files/92826da3-9606-49ad-8d4e-8412d4fdd21a/video_preview_h264.mp4'
      Uri.parse(
          'https://assets.mixkit.co/videos/preview/mixkit-stock-market-exchange-and-forex-prices-background-47006-large.mp4'), // Convert String URL to Uri
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
    _videoController.dispose();
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
