// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math; // Import the math library

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:games_services/games_services.dart';
import 'package:http/http.dart' as http;

import 'package:path/path.dart' as p;
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zmoney/fukk_widgets/app_assets.dart';
import 'package:zmoney/fukk_widgets/language_selector.dart';
import 'package:zmoney/fukk_widgets/skin.dart';
import 'package:zmoney/fukk_widgets/translator.dart';
import 'package:zmoney/marquee.dart';
import 'package:zmoney/ngrok.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:zmoney/side_menu.dart';
import 'package:zmoney/text_cycle.dart';
import 'package:zmoney/tutorial_steps.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'package:auto_size_text/auto_size_text.dart';

final translator =
    Translator(currentLanguage: 'en'); // Set initial language as needed

// Import the necessary library

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  static DateTime? lastUpdateTime;

  DateTime? lastPressed;
  int _remainingTime = 600;
  late bool _timerStarted = false;
  late BannerAd _bannerAd;
  RewardedAd? _rewardedAd; // Declare _rewardedAd as nullable
  bool _isRewardedAdReady = false;
// Add a new boolean to track if the timer has finished.
  bool _timerFinished = false;
  bool _isBannerAdReady = false;
// State to manage tutorial visibility
// State for party animation
  final TextEditingController _numberController = TextEditingController();
  late TutorialManager tutorialManager;
  Key playerDataWidgetKey = UniqueKey();

  bool _isWaitingForResponse = false;

  Timer? _smoothIncrementationTimer;
  double _incrementAmountPerInterval = 0.0;
  final int _smoothUpdateIntervalMs = 5000; // Update every 100 milliseconds

// To keep track of tutorial steps
  late ConfettiController _confettiController; // ConfettiControllerpla
  int randomAnimationType = 1; // Default to 1 or any valid animation type
  // GlobalKeys for target widgets
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey keyLanguageSelector = GlobalKey();
  // Add more keys as needed
// Default language code

  List<String> translatedTexts = [
    'How Much?',
    'Enter your lucky number',
    'Submit your guess here!',
    'Ready',
    'Time remaining',
    'Money withdrawal',
    'Your current prize:',
    'Here you can enter numbers.',
    'Enter numbers in this field.',
    'Select your language here',
    'Game Menu',
    'How to play: Enter numbers & test your luck.',
    'You can win various prices, including real money.',
    'Account inventory',
    'Settings',
    'Try swiping here', // Ensure there's a comma here
    'Current reward:',
    'Application still under heavy development!   ',
    'Rules',
    'Game Menu',
  ]; // Make it an empty, growable list

  double _prizePoolAmount = 100000; // Starting amount
  double _conversionRatio = 0.1; // Adjusted for demonstration

// To track the Go button lock state
  bool isButtonLocked = false; // Add this variable to your widget state
  List<TutorialStep> tutorialSteps = [];
  final bool _isGreenText = true; // Define _isGreenText as a boolean variable

// Default color, can be black or white

  Duration animationDuration = const Duration(seconds: 5);

  bool useTexture = false; // Flag to toggle between color and texture
  int currentSkin = 1; // Default skin. Adjust based on how many skins you have.
  int currentSkinIndex = 0; // Default to the first skin

  List<Skin> skins = [
    Skin(
      backgroundColor: Colors.black,
      prizePoolTextColor: Colors.lightGreen,
      textColor: Colors.white,
      specialTextColor: Colors
          .white, // Assuming you've added this property based on previous instructions
      buttonColor: Colors.black,
      buttonTextColor: Colors.white,
      textColorSwitchTrue: Colors.lightGreenAccent, // True condition color
      textColorSwitchFalse: Colors.lightGreen, // False condition color
      decoration: const BoxDecoration(color: Colors.black),
    ),
    Skin(
      backgroundColor: Colors.white,
      prizePoolTextColor: Colors.blueAccent,
      textColor: Colors.white,
      specialTextColor: Colors.white, // Example special text color
      buttonColor: Colors.black,
      buttonTextColor: Colors.white,
      textColorSwitchTrue: Colors.lightGreenAccent, // True condition color
      textColorSwitchFalse: Colors.lightGreen, // False condition color
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/texture1.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    Skin(
      backgroundColor: const Color(0xFF4A2040), // Dark Amethyst
      prizePoolTextColor: const Color(0xFFE0B0FF), // Mauve
      textColor: const Color(0xFFF8E8FF), // Very Pale Purple
      specialTextColor: const Color(0xFFDEC0E6), // Thistle
      buttonColor: const Color(0xFF6A417A), // Medium Amethyst
      buttonTextColor: const Color(0xFFF8E8FF), // Very Pale Purple
      textColorSwitchTrue: const Color(0xFFCDA4DE), // Pastel Violet
      textColorSwitchFalse: const Color(0xFFB0A8B9), // Greyish Lavender
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/texture2.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    Skin(
      backgroundColor: const Color(0xFF0B3D2E), // Dark Green
      prizePoolTextColor: Colors.white, // Bright Green
      textColor: const Color(0xFFE9E4D0), // Light Beige
      specialTextColor: const Color(0xFFD1E8D2), // Pale Green
      buttonColor: const Color(0xFF507C59), // Moss Green
      buttonTextColor: const Color(0xFFE9E4D0), // Light Beige
      textColorSwitchTrue: const Color(0xFFD1E8D2), // Pale Green
      textColorSwitchFalse: const Color(0xFF6C8E67), // Sage Green
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/texture3.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    Skin(
      backgroundColor: Colors.brown[800]!, // Deep wood color
      prizePoolTextColor: Colors.white, // Warm amber for highlights
      textColor: Colors.white, // High contrast for readability
      specialTextColor: Colors.white, // Earthy orange for special texts
      buttonColor:
          Colors.green[800]!, // Dark green for buttons, resembling forest
      buttonTextColor:
          Colors.white, // White text for clear readability on buttons
      textColorSwitchTrue: Colors.amber, // Warm amber for true state
      textColorSwitchFalse:
          Colors.brown[600]!, // Slightly lighter wood color for false
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/texture4.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
  ];
  late Directory directory; // To hold the application directory path

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _preventAd =
      false; // Flag to prevent ad from showing on consecutive guesses
  bool _arrowsVisible = true;
  late AnimationController _glowController; // Renamed for clarity
  late Animation<double> _glowAnimation; // Renamed for clarity
  static const platform = MethodChannel('com.gg.zmoney/game_services');

  //INIT STATE <<<<<<<<<<<<<<<<<<<<
  @override
  void initState() {
    super.initState();
    _initSkinsAndDirectory();

    initializeTranslations();
    WidgetsBinding.instance.addObserver(this); // Add the observer
    if (!kDebugMode && !kProfileMode) {
      _initBannerAd();
      _loadRewardedAd();
    }
    _loadRewardedInterstitialAd();

    _fetchPrizePoolFromServer();
    _confettiController = ConfettiController();
    //_confettiController.play();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(_glowController); // Use the controller for the glow effect

    _glowController.repeat(reverse: true);
    // Attempt to sign in to Game Services
    // Initialize VideoPlayerManager
    VideoPlayerManager().init().then((_) {
      // Now it's safe to use VideoPlayerManager, maybe set a flag to indicate readiness
    });
    // Check if the tutorial has been completed previously
  }

  Future<void> _initSkinsAndDirectory() async {
    directory =
        await getApplicationDocumentsDirectory(); // This sets the directory before using it
    skins = _createSkins(); // Now it's safe to call _createSkins()
    setState(() {}); // Trigger rebuild with initialized skins
  }

  List<Skin> _createSkins() {
    return [
      Skin(
        backgroundColor: Colors.black,
        prizePoolTextColor: Colors.lightGreen,
        textColor: Colors.white,
        specialTextColor: Colors
            .white, // Assuming you've added this property based on previous instructions
        buttonColor: Colors.black,
        buttonTextColor: Colors.white,
        textColorSwitchTrue: Colors.lightGreenAccent, // True condition color
        textColorSwitchFalse: Colors.lightGreen, // False condition color
        decoration: const BoxDecoration(color: Colors.black),
      ),
      Skin(
        backgroundColor: Colors.white,
        prizePoolTextColor: Colors.blueAccent,
        textColor: Colors.white,
        specialTextColor: Colors.white, // Example special text color
        buttonColor: Colors.black,
        buttonTextColor: Colors.white,
        textColorSwitchTrue: Colors.lightGreenAccent, // True condition color
        textColorSwitchFalse: Colors.lightGreen, // False condition color
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File('${directory.path}/textures/texture1.jpg')),
            fit: BoxFit.cover,
          ),
        ),
      ),
      Skin(
        backgroundColor: const Color(0xFF4A2040), // Dark Amethyst
        prizePoolTextColor: const Color(0xFFE0B0FF), // Mauve
        textColor: const Color(0xFFF8E8FF), // Very Pale Purple
        specialTextColor: const Color(0xFFDEC0E6), // Thistle
        buttonColor: const Color(0xFF6A417A), // Medium Amethyst
        buttonTextColor: const Color(0xFFF8E8FF), // Very Pale Purple
        textColorSwitchTrue: const Color(0xFFCDA4DE), // Pastel Violet
        textColorSwitchFalse: const Color(0xFFB0A8B9), // Greyish Lavender
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File('${directory.path}/textures/texture2.jpg')),
            fit: BoxFit.cover,
          ),
        ),
      ),
      Skin(
        backgroundColor: const Color(0xFF0B3D2E), // Dark Green
        prizePoolTextColor: Colors.white, // Bright Green
        textColor: const Color(0xFFE9E4D0), // Light Beige
        specialTextColor: const Color(0xFFD1E8D2), // Pale Green
        buttonColor: const Color(0xFF507C59), // Moss Green
        buttonTextColor: const Color(0xFFE9E4D0), // Light Beige
        textColorSwitchTrue: const Color(0xFFD1E8D2), // Pale Green
        textColorSwitchFalse: const Color(0xFF6C8E67), // Sage Green
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File('${directory.path}/textures/texture3.jpg')),
            fit: BoxFit.cover,
          ),
        ),
      ),
      Skin(
        backgroundColor: Colors.brown[800]!, // Deep wood color
        prizePoolTextColor: Colors.white, // Warm amber for highlights
        textColor: Colors.white, // High contrast for readability
        specialTextColor: Colors.white, // Earthy orange for special texts
        buttonColor:
            Colors.green[800]!, // Dark green for buttons, resembling forest
        buttonTextColor:
            Colors.white, // White text for clear readability on buttons
        textColorSwitchTrue: Colors.amber, // Warm amber for true state
        textColorSwitchFalse:
            Colors.brown[600]!, // Slightly lighter wood color for false
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File('${directory.path}/textures/texture4.jpg')),
            fit: BoxFit.cover,
          ),
        ),
      ),
    ];
  }

  void _loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-4652990815059289/7189734426',
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedInterstitialAd = null;
        },
      ),
    );
  }

  Future<void> initializeTranslations() async {
    List<String> keys = [
      'How Much?',
      'Enter your lucky number',
      'Submit your guess here!',
      'Ready',
      'Time remaining',
      'Money withdrawal',
      'Your current prize:',
      'Here you can enter numbers.',
      'Enter numbers in this field.',
      'Select your language here',
      'Game Menu',
      'How to play: Enter numbers & test your luck.',
      'You can win various prices, including real money.',
      'Account inventory',
      'Settings',
      'Try swiping here', // Ensure there's a comma here
      'Current reward:',
      'Application still under heavy development!   ',
      'Rules',
      'Game Menu',
      // Add more keys as needed
    ];

    // Assuming `translator` is your instance of the Translator class
    List<Future<String>> translationFutures =
        keys.map((key) => translator.translate(key)).toList();

    // Wait for all translations to complete
    List<String> results = await Future.wait(translationFutures);

    // Once all futures are resolved, update your state
    setState(() {
      translatedTexts =
          results; // This list now directly reflects the keys translated

      tutorialManager = TutorialManager(
        translatedTexts: translatedTexts,
        keys: [keyLanguageSelector, key1, key2, key3],
        onUpdate: () => setState(() {}),
      );
    });
  }

  Future<void> _showRewardedInterstitialAd() async {
    if (_rewardedInterstitialAd == null) {
      return;
    }
    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        ad.dispose();
        _loadRewardedInterstitialAd();
        _preventAd = true; // Prevent ad from showing on the next guess
      },
      onAdFailedToShowFullScreenContent:
          (RewardedInterstitialAd ad, AdError error) {
        ad.dispose();
        _loadRewardedInterstitialAd();
      },
    );
    _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      // Handle reward
      _timerFinished = true;
    });
    _rewardedInterstitialAd = null;
  }

  Future<void> _fetchPrizePoolFromServer() async {
    const secureStorage = FlutterSecureStorage();
    try {
      final jwtToken = await secureStorage.read(key: 'jwtToken');
      final uri = Uri.parse('${NgrokManager.ngrokUrl}/api/prizePool');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        if (data != null) {
          setState(() {
            _prizePoolAmount = data['prizePoolBase'].toDouble();
            // Correctly update the class field _conversionRatio
            _conversionRatio = data['conversionRatio'];
            _startSmoothPrizePoolIncrementation();
          });
          // This should now print the updated value
        }
      } else {
        throw Exception('Failed to load prize pool from server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching prize pool: ${e.toString()}');
      }
      // Handle the error appropriately
    }
  }

  void _startSmoothPrizePoolIncrementation() {
    const averageIncrementPerUpdate = (100 + 600) / 2;
    // Halving the increment rate in addition to halving the speed
    const updateIntervalSeconds =
        2; // Considering this as the basis for speed reduction
    const averageIncrementPerSecond = averageIncrementPerUpdate /
        updateIntervalSeconds /
        2; // Halving the increment rate

    // Further adjusting the increment amount per interval for half-rate updates
    _incrementAmountPerInterval =
        averageIncrementPerSecond * (_smoothUpdateIntervalMs / 1000.0) / 2;

    // Initialize or reset the smooth incrementation timer to 10 seconds, with the new half-rate adjustment
    _smoothIncrementationTimer?.cancel();
    _smoothIncrementationTimer = Timer.periodic(
        Duration(milliseconds: _smoothUpdateIntervalMs * 2), (timer) {
      setState(() {
        _prizePoolAmount += _incrementAmountPerInterval;
      });
    });
  }

  Future<bool> onWillPop() async {
    final now = DateTime.now();
    if (lastPressed == null ||
        now.difference(lastPressed!) > const Duration(seconds: 2)) {
      lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit"),
          duration: Duration(seconds: 2),
        ),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

/*
  Future<Map<String, dynamic>> requestToken() async {
    // Ensure Ngrok URL is fetched and updated
    await NgrokManager.fetchNgrokData();

    // Check if Ngrok URL is available
    if (NgrokManager.ngrokUrl.isEmpty) {
      // Handle error: Ngrok URL not available
      throw Exception('Ngrok URL is not available');
    }

    // Collect user details
    Map<String, dynamic> userDetails = await fetchUserDetails();

    // Collect device information
    Map<String, dynamic> deviceInfo = await getDeviceInfo();

    // Fetch the app verification hash from environment variables
    String appVerificationHash =
        FlutterConfig.get('APP_VERIFICATION_HASH').toString();

    // Prepare the request payload with additional device information
    Map<String, dynamic> payload = {
      "userDetails": userDetails,
      "deviceInfo": deviceInfo,
      "appVerification": appVerificationHash,
      // Add any other necessary data
    };

    // Make the token request to the server using Ngrok URL
    final response = await http.post(
      Uri.parse('${NgrokManager.ngrokUrl}/api/requestToken'),
      headers: {
        "Content-Type": "application/json",
        // Additional headers as needed
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      // Parse the response and return
      return json.decode(response.body);
    } else {
      // Handle errors
      throw Exception('Failed to request token: ${response.body}');
    }
  }
*/

  void _playConfettiAnimation() {
    // Check if the controller is already playing, to avoid restarting it unnecessarily
    if (_confettiController.state != ConfettiControllerState.playing) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Ensure the timer is canceled when the widget is disposed
    _smoothIncrementationTimer
        ?.cancel(); // Cancel the smooth incrementation timer
    _bannerAd.dispose(); // Dispose of _bannerAd safely
    _rewardedAd?.dispose();
    _rewardedAd = null; // Then set _rewardedAd to null to clean up references

    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Only initialize or load ads when the app resumes to avoid unnecessary memory usage
      _isBannerAdReady ? null : _initBannerAd(); // Conditional loading
      _isRewardedAdReady ? null : _loadRewardedAd(); // Conditional loading
      _fetchPrizePoolFromServer();
    }
  }

  void _loadRewardedAd() {
    if (!_isRewardedAdReady && _rewardedAd == null) {
      RewardedAd.load(
        adUnitId: 'ca-app-pub-4652990815059289/8386402654',
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            setState(() {
              _rewardedAd = ad;
              _isRewardedAdReady = true;
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              print('RewardedAd failed to load: $error');
            }
            setState(() {
              _isRewardedAdReady = false;
            });
            _retryLoadRewardedAd();
          },
        ),
      );
    }
  }

  // Function to handle the press of the ad button
  void _onPressAdButton() {
    // Close the keyboard
    FocusScope.of(context).unfocus();

    // After a brief delay to ensure the keyboard is closed, show the rewarded ad
    Future.delayed(const Duration(milliseconds: 300), () {
      _showRewardedAd();
    });
  }

  void _showRewardedAd() {
    if (_isRewardedAdReady) {
      _rewardedAd?.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // User has earned the reward. Implement any logic needed when a reward is earned.
          // Example: Call a method to skip timer or unlock content
          _timerFinished = true;
          _timerStarted = false;
          isButtonLocked = false; // Unlock the Go button here as well
        },
      );

      _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (AdWithoutView ad) {
          // Dispose of the ad when it's dismissed to free up resources
          ad.dispose();
          // Preemptively load a new rewarded ad for future use
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (AdWithoutView ad, AdError error) {
          // Log or handle the error if the ad fails to show
          if (kDebugMode) {
            print('Failed to show rewarded ad: $error');
          }
          // Dispose of the ad to free up resources
          ad.dispose();
          // Attempt to load a new rewarded ad
          _loadRewardedAd();
        },
        // Consider handling other callback events if needed
      );
    } else {
      // This block executes if the rewarded ad is not ready to be shown
      // Log this status or inform the user as needed
      if (kDebugMode) {
        print('Rewarded ad is not ready yet.');
      }
      // Optionally, trigger a load or retry mechanism for the rewarded ad here
    }
  }

  void _initBannerAd() {
    // Initialize the BannerAd instance and assign it to the _bannerAd variable.
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-4652990815059289/6968524603', // Replace with your ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          // When the ad is loaded, set _isBannerAdReady to true and update the UI as needed
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Handle the error when loading an ad fails
          _retryLoadRewardedAd;
          if (kDebugMode) {
            print('BannerAd failed to load: $error');
          }
          ad.dispose(); // Dispose the ad to free up resources
          // Optionally, implement a retry mechanism or update UI to reflect the failure
        },
        // You may handle other ad lifecycle events, such as onAdOpened, onAdClosed, etc.
      ),
    );

    // Load the ad
    _bannerAd.load();
  }

  void _retryLoadRewardedAd({int attempt = 1}) {
    const maxAttempts = 3;
    if (attempt <= maxAttempts) {
      Future.delayed(Duration(seconds: attempt * 2), () => _loadRewardedAd());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _toggleSkin(bool isIncrementing) {
    setState(() {
      _arrowsVisible = false;
      if (isIncrementing) {
        // Increment the index and wrap around if necessary
        currentSkinIndex = (currentSkinIndex + 1) % skins.length;
      } else {
        // Decrement the index and wrap around if necessary
        currentSkinIndex = (currentSkinIndex - 1 + skins.length) % skins.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

// Use the currentSkinIndex to get the current Skin object

    Skin currentSkin = skins[currentSkinIndex];
    // Calculate maxBlastForce based on screen width, with a maximum limit
    double calculatedBlastForce = screenSize.width / 1; // Example calculation
    double maxAllowedBlastForce = 1800; // Set your maximum limit here
    double maxBlastForce = math.min(calculatedBlastForce, maxAllowedBlastForce);
    final bannerAdHeight = _isBannerAdReady
        ? 50.0
        : 0.0; // Example ad height, adjust based on actual ad size

    return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: SideMenuDrawer(
            translatedTexts: translatedTexts,
            containerColor: currentSkin.specialTextColor,
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _arrowsVisible = false;
                if (_arrowsVisible) {
                  // Start or restart the glowing effect when arrows become visible
                  _glowController.repeat(reverse: true);
                } else {
                  // Stop the animation when arrows are hidden
                  _glowController.stop();
                }
              });
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1),
                  color: currentSkin.backgroundColor,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // Animated background container

                      GestureDetector(
                        onHorizontalDragEnd: (DragEndDetails details) {
                          // Check the velocity of the drag to determine swipe direction
                          if (details.primaryVelocity! > 0) {
                            // User swiped Left to Right
                            _toggleSkin(
                                false); // Call _toggleSkin to decrement the index
                          } else if (details.primaryVelocity! < 0) {
                            // User swiped Right to Left
                            _toggleSkin(
                                true); // Call _toggleSkin to increment the index
                          }
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(
                              milliseconds: 1000), // Smooth transition duration
                          child: Container(
                            key: ValueKey<int>(
                                currentSkinIndex), // Unique key based on current skin
                            decoration: skins[currentSkinIndex]
                                .decoration, // Use current skin's decoration
                            width: screenSize.width,
                            height: screenSize.height,
                          ),
                        ),
                      ),

                      if (_isBannerAdReady)
                        Positioned(
                          top: 40, // Banner ad at the top
                          child: SizedBox(
                            width: screenSize.width,
                            height:
                                bannerAdHeight, // Adjust based on actual ad size
                            child: AdWidget(ad: _bannerAd), // Your banner ad
                          ),
                        ),

                      Positioned(
                        top: 33 +
                            (_isBannerAdReady
                                ? bannerAdHeight
                                : 40), // Dynamically adjust based on ad readiness
                        left: 20,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: Icon(Icons.menu,
                                color: currentSkin.textColor, size: 30.0),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 33 +
                            (_isBannerAdReady
                                ? bannerAdHeight
                                : 40), // Dynamically adjust based on ad readiness
                        right: 20,
                        child: LanguageSelectorWidget(
                          onLanguageChanged: (String newLanguageCode) {
                            initializeTranslations();

                            setState(() {});
                          },
                          dropdownColor: currentSkin.buttonColor,
                          textColor:
                              currentSkin.buttonTextColor, // Custom text color
                          iconColor:
                              currentSkin.specialTextColor, // Custom icon color
                          underlineColor: currentSkin
                              .backgroundColor, // Custom underline color
                        ),
                      ),
                      // Confetti Widget
                      Align(
                        alignment: Alignment.topRight,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          blastDirection: -math.pi / 1,
                          particleDrag: 0.05,
                          emissionFrequency: 0.05,
                          numberOfParticles: 7,
                          gravity: 0.01,
                          colors: const [Colors.green],
                          minBlastForce: 1,
                          maxBlastForce:
                              maxBlastForce, // Ensure this is defined in your state
                        ),
                      ),

                      if (_arrowsVisible)
                        Positioned(
                          top: screenSize.height / 2 +
                              200, // Adjusted for better alignment
                          left: 0,
                          right: 0,
                          child: AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _glowAnimation.value,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.chevron_left,
                                          size: 60,
                                          color: currentSkin.specialTextColor
                                              .withOpacity(
                                                  _glowAnimation.value)),
                                      onPressed: () => _toggleSkin(false),
                                    ),
                                    Text(
                                      translatedTexts[15],
                                      style: TextStyle(
                                        fontFamily: 'Proxima',
                                        fontWeight: FontWeight
                                            .w700, // This applies the italic font with weight 700 based on your pubspec declaration
                                        color: currentSkin.specialTextColor
                                            .withOpacity(_glowAnimation.value),
                                        fontSize: 20,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0.0, 0.0),
                                            blurRadius: 12.0,
                                            color: currentSkin.specialTextColor
                                                .withOpacity(
                                                    _glowAnimation.value),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.chevron_right,
                                          size: 60,
                                          color: currentSkin.specialTextColor
                                              .withOpacity(
                                                  _glowAnimation.value)),
                                      onPressed: () => _toggleSkin(true),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const TextCycleWidget(),
                                      _buildNumberInput(
                                          screenSize, translatedTexts[1]),
                                      /* Text(
                                  translatedTexts[0], // Use translated text
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),*/
                                      const SizedBox(height: 16),
                                      _buildGoButton(screenSize,
                                          translatedTexts[2], isButtonLocked),
                                      // Modified Skip Button to show Rewarded Ad
                                      if (_timerStarted && _isRewardedAdReady)
                                        TextButton(
                                          onPressed: _onPressAdButton,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds:
                                                    500), // Speed of fade effect
                                            child: Row(
                                              mainAxisSize: MainAxisSize
                                                  .min, // To keep the row tight around its children
                                              children: [
                                                Icon(Icons.touch_app,
                                                    color: currentSkin
                                                        .prizePoolTextColor),
                                                const SizedBox(
                                                    width:
                                                        5), // A little spacing between the icon and text
                                                Text(
                                                  "Watch ad to guess again right now!",
                                                  key:
                                                      UniqueKey(), // Important for unique identification
                                                  style: TextStyle(
                                                    color: _isGreenText
                                                        ? currentSkin
                                                            .textColorSwitchTrue
                                                        : currentSkin
                                                            .textColorSwitchFalse,
                                                    fontSize: 18,
                                                    shadows: _isGreenText
                                                        ? [
                                                            Shadow(
                                                              blurRadius: 10.0,
                                                              color: currentSkin
                                                                  .textColorSwitchFalse,
                                                              offset:
                                                                  const Offset(
                                                                      0, 0),
                                                            ),
                                                          ]
                                                        : [],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ]),
                              ),
                            ),
                          ),
                        ],
                      ),

                      //  PlayerDataWidget(key: playerDataWidgetKey),

                      // Marquee Text Positioned
                      if (!isKeyboardOpen)
                        Positioned(
                          bottom: -10, // Adjust as needed
                          child: SizedBox(
                            key: key3,
                            width: screenSize.width,
                            height: 40, // Adjust the height as needed
                            child: MarqueeText(
                              text: ('${translatedTexts[17]}⚠️' * 20),
                              style: TextStyle(
                                color: currentSkin.specialTextColor
                                    .withOpacity(0.5), // 50% opacity
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (!isKeyboardOpen)
                        // Only show the prize pool counter if the keyboard is not open
                        _buildPrizePoolCounter(isKeyboardOpen),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Stack(
            children: [
              Positioned(
                  right: 10,
                  bottom: 5,
                  child: StatisticsFloatingButton(
                    conversionRatio:
                        _conversionRatio, // Ensure this is the current conversion ratio obtained from your logic
                  )),
            ],
          ),
        ));
  }

  Widget _buildNumberInput(Size screenSize, String hintText) {
    return SizedBox(
      width: screenSize.width * 0.8,
      child: Container(
        width: screenSize.width * 0.8,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: TextField(
          key: key1, // Assign the GlobalKey here
          controller: _numberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText, // Use the translated text
            contentPadding: const EdgeInsets.fromLTRB(10, 12, 10,
                10), // Adjust padding to center the hint text vertically

            suffixIconConstraints: const BoxConstraints(
                minWidth: 48, minHeight: 22), // Adjust icon size
          ),
          textAlign: TextAlign.center, // Horizontally centers the text
          style: const TextStyle(
            fontSize: 15.0, // Font size, adjusted to match _buildGoButton
            fontWeight: FontWeight.bold, // Bold font
            color: Colors.black, // Text color
            letterSpacing: 1.2, // Letter spacing
            fontFamily: 'Inter', // Keep the same font family
          ),
          onTap: _playConfettiAnimation, // Play confetti on interaction
        ),
      ),
    );
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer?.cancel(); // Cancel any existing timer first

    final endTime = DateTime.now().add(Duration(seconds: _remainingTime));
    _timerStarted = true;
    _timerFinished = false;

    _timer = Timer.periodic(oneSec, (Timer timer) {
      final secondsLeft = endTime.difference(DateTime.now()).inSeconds;
      if (secondsLeft < 0) {
        timer.cancel();
        onTimerEnd();
      } else {
        // Throttle UI updates to every few seconds to reduce rebuilds
        if (_remainingTime - secondsLeft >= 5 || secondsLeft == 0) {
          setState(() {
            _remainingTime = secondsLeft;
          });
        }
      }
    });

    // Ensure initial state is set outside the periodic callback
    setState(() {});
  }

  void onTimerEnd() {
    setState(() {
      _timerFinished = true; // Mark timer as finished
      isButtonLocked = false; // Unlock the "Go" button
      _timerStarted = false; // Mark timer as not started
    });

    // Perform any additional actions needed when the timer ends
  }

  void _showEmptyTextFieldNotification() {
    const snackBar = SnackBar(
      content: Text("You have to enter some numbers to win💲💲..."),
      duration: Duration(seconds: 5),
    );

    // Use ScaffoldMessenger to show the SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildPrizePoolCounter(bool keyboardOpen) {
    double bottomPosition =
        keyboardOpen ? 100 : 20; // Adjust position based on keyboard visibility

    Skin currentSkin = skins[currentSkinIndex];
    return Positioned(
      bottom: bottomPosition,
      left: 0,
      right: 0,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the dimensions for the pill
            double textHeight = 24; // Assuming this is the text height
            double pillWidth = 200; // textWidth + textHeight;
            double pillHeight =
                textHeight * 2; // Adjusted calculation for pill height

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  translatedTexts[16],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: currentSkin.specialTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: pillWidth,
                  height: pillHeight,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(128, 255, 255, 255),
                    borderRadius: BorderRadius.circular(pillHeight / 2),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedFlipCounter(
                        duration: const Duration(milliseconds: 500),
                        value:
                            _prizePoolAmount, // Assuming this is defined elsewhere
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: currentSkin
                              .prizePoolTextColor, // Correctly using runtime value
                          fontFamily: 'Digital-7',
                          shadows: [
                            Shadow(
                                offset: const Offset(-1.5, -1.5),
                                color: currentSkin.prizePoolTextColor
                                    .withOpacity(0.2)),
                            Shadow(
                                offset: const Offset(1.5, 1.5),
                                color: currentSkin.prizePoolTextColor
                                    .withOpacity(0.2)),
                          ],
                        ),
                        prefix: "ⓩ",
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoButton(Size screenSize, String buttonText, bool isLocked) {
    // Define the default and loading button colors
    Skin currentSkin = skins[currentSkinIndex];
    // Change to your desired default color
    // Change to your desired loading color
    Color color1 = currentSkin.textColor;

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        setState(() {
          color1 = currentSkin.textColor
              .withOpacity(0.7); // Button is being pressed down
        });
      },
      onTap: () {
        _playConfettiAnimation();
        if (!isLocked && !_isWaitingForResponse && !_timerStarted) {
          submitGuess();
        } else if (isLocked && _timerFinished) {
          // Optionally handle a tap when the button is locked but the timer finished
          setState(() {
            _timerFinished = false; // Reset timer finished state
          });
        }
      },
      child: Container(
        width: screenSize.width * 0.8,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 10), // Uniform padding
        decoration: BoxDecoration(
          color:
              color1.withOpacity(0.2), // Slight transparency for the background
          borderRadius: BorderRadius.circular(25), // Pill-shaped border radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25), // Shadow with 25% opacity
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 4), // Vertically displaced shadow
            ),
          ],
        ),
        child: _isWaitingForResponse
            ? const CircularProgressIndicator()
            : Center(
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min, // Row size adjusts to its content
                  children: [
                    if (isLocked)
                      Icon(
                        Icons.lock, // Lock icon indicating the button is locked
                        color: currentSkin.textColor,
                        size: 23.0,
                      ),
                    if (isLocked)
                      const SizedBox(
                          width:
                              5), // Space between the icon and text if locked
                    Expanded(
                      // This wraps the AutoSizeText to prevent overflow
                      child: AutoSizeText(
                        _timerStarted
                            ? '${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
                            : isLocked
                                ? ""
                                : buttonText,
                        style: TextStyle(
                          fontSize: 23.0, // Start size before auto-sizing
                          fontWeight: FontWeight.bold,
                          color: currentSkin
                              .specialTextColor, // Adjusted for dynamic color usage
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        minFontSize: 10, // Minimum text size
                        maxFontSize: 23,
                        maxLines: 1, // Ensure text does not wrap
                        overflow: TextOverflow
                            .ellipsis, // Handles cases where text can't scale down enough
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> submitGuess() async {
    // Assuming NgrokManager.fetchNgrokData() and _numberController are defined elsewhere correctly
    //await NgrokManager.fetchNgrokData();
    String guessStr = _numberController.text;

    if (guessStr.isEmpty) {
      _showEmptyTextFieldNotification();
      return;
    }

    setState(() {
      _isWaitingForResponse = true;
    });

    if (NgrokManager.ngrokUrl.isEmpty) {
      setState(() {
        _isWaitingForResponse = false;
      });
      _showServerNotRunningDialog();
      return;
    }

    int? guessInt = int.tryParse(guessStr);
    if (guessInt == null) {
      setState(() {
        _isWaitingForResponse = false;
      });
      return;
    }

    // Retrieve userId and prizePoolAmount
    final prefs = await SharedPreferences.getInstance();
    final String playerDataJson = prefs.getString('playerData') ?? '{}';
    var playerData = jsonDecode(playerDataJson);

    // Retrieve or define userId and prizePoolAmount here
    final int userId =
        playerData['user_id']; // Example retrieval from player data

    try {
      var response = await http.post(
        Uri.parse('${NgrokManager.ngrokUrl}/api/guess'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'guess': guessInt,
          'userId': userId, // Now using the retrieved or defined userId
        }),
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        bool isCorrect = result['correct'];

        final prefs = await SharedPreferences.getInstance();
        final String playerDataJson = prefs.getString('playerData') ?? '{}';
        var playerData = jsonDecode(playerDataJson);
        double prizePoolAmount =
            _prizePoolAmount.toDouble(); // Assuming this is already a double

        // Update guess count and potentially other fields based on guess correctness
        playerData['total_guesses'] = (playerData['total_guesses'] ?? 0) + 1;
        if (isCorrect) {
          unlockAchievement('CgkIipShgv8MEAIQCA');
          _preventAd = true;
          playerData['wins'] = ((playerData['wins'] ?? 0) as int) + 1;
          playerData['total_win_amount'] =
              (playerData['total_win_amount'] ?? 0.0) + prizePoolAmount;
          if (prizePoolAmount >
              (playerData['highest_win_amount']?.toDouble() ?? 0.0)) {
            playerData['highest_win_amount'] = prizePoolAmount;
          }
        }
        // Update last_guesses
        List<String> guesses = (playerData['last_guesses'] != null)
            ? List<String>.from(playerData['last_guesses'].split(','))
            : [];
        guesses.add(guessStr); // Add the new guess to the list
        playerData['last_guesses'] =
            guesses.join(','); // Convert list back to string and save

        await prefs.setString('playerData', jsonEncode(playerData));
        // Refresh UI and PlayerDataWidget

        double actualPrizePool =
            double.parse(result['actualPrizePool'].toString());
        // Now submit this actualPrizePool value as the score

        await Leaderboards.submitScore(
            score: Score(
                androidLeaderboardID: 'CgkIipShgv8MEAIQAg',
                value: actualPrizePool.toInt()));

        setState(() {
          _isWaitingForResponse = false;
          isButtonLocked = true;
          _showResultDialog(isCorrect);
          _remainingTime = 600;
          startTimer();
          playerDataWidgetKey =
              UniqueKey(); // This forces the PlayerDataWidget to rebuild and reload data
        });
        //_showResultDialog(isCorrect);
      } else {
        setState(() {
          _isWaitingForResponse = false;
        });
        // Consider showing an error dialog or notification here
      }
    } catch (e) {
      setState(() {
        _isWaitingForResponse = false;
      });

      // Implement the 33% chance logic and check the _preventAd flag
      if (!_preventAd && math.Random().nextInt(3) == 0) {
        // Approximately 33% chance
        await _showRewardedInterstitialAd();
      } else {
        // If an ad was shown last time, reset the flag to allow showing ads again
        if (_preventAd) {
          _preventAd = false;
        }
      }
      _showServerNotRunningDialog();
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    try {
      final bool result = await platform
          .invokeMethod('unlockAchievement', {'achievementId': achievementId});
      if (kDebugMode) {
        print(result);
      }
    } on PlatformException {
      if (kDebugMode) {
        print('achievement error');
      }
    }
  }

  void _showServerNotRunningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isCheckingServer = true;
        String dialogMessage = 'Server might be down ...';
        Color dialogColor = Colors.blueAccent;

        Timer? timer;

        void checkServerAvailability() {
          timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
            bool fetched = await NgrokManager.fetchNgrokData2();

            if (fetched && NgrokManager.ngrokUrl.isNotEmpty) {
              try {
                final apiResponse = await http
                    .get(Uri.parse('${NgrokManager.ngrokUrl}/api/test'));

                if (apiResponse.statusCode == 200) {
                  // Connection successful
                  if (context.mounted) {
                    setState(() {
                      dialogMessage = 'Connected successfully!';
                      dialogColor = Colors.green;
                    });

                    // Wait for a few seconds to show the updated UI
                    await Future.delayed(const Duration(seconds: 2), () {
                      setState(() {
                        isCheckingServer = false;
                      });
                    });

                    t.cancel();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  }
                }
              } catch (e) {
                // Error during API call, handle if needed
              }
            } else {
              // Ngrok URL not fetched or empty
              t.cancel();
              if (context.mounted) {
                Navigator.of(context).pop(false);
              }
            }
          });
        }

        checkServerAvailability();

        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dialogColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedCrossFade(
                        firstChild: const CircularProgressIndicator(),
                        secondChild: const Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.white),
                        crossFadeState: isCheckingServer
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dialogMessage,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        child: const Text('OK',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          timer?.cancel();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showResultDialog(bool isCorrect) {
    if (isCorrect) {
      _confettiController.play();

      showDialog(
        context: context,
        barrierDismissible: false, // Disable closing by tapping outside
        builder: (BuildContext context) {
          // Use _prizePoolAmount directly if it's already updated
          return WillPopScope(
            onWillPop: () async =>
                false, // Prevent dialog from closing on back press
            child:
                _buildWinOverlay(context, _prizePoolAmount), // Corrected call
          );
        },
      );
      _fetchPrizePoolFromServer();
    } else {
      showDialog(
        context: context,
        barrierDismissible: false, // Disable closing by tapping outside
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child:
                _buildLoseOverlay(), // Assuming _buildLoseOverlay is defined elsewhere
          );
        },
      );
    }
  }

  Future<void> playVictorySound() async {
    final audioPlayer = AudioPlayer();

    // Ensure appDocumentsDirectory is initialized before using it.
    if (appDocumentsDirectory == null) {
      appDocumentsDirectory = await getApplicationDocumentsDirectory();
    }

    // Directly construct the path using appDocumentsDirectory
    final soundFilePath =
        p.join(appDocumentsDirectory!.path, 'sounds/victory_sound.mp3');

    if (await File(soundFilePath).exists()) {
      await audioPlayer.play(DeviceFileSource(soundFilePath));
    } else {
      print('Victory sound file does not exist.');
      // Handle the case where the file doesn't exist as needed
    }
  }

  Future<String> _localAssetPath(String localPath) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, localPath);
  }

  Widget _buildWinOverlay(BuildContext context, double prizePoolAmount) {
    // Assuming this is a top-level function or part of a class that has access to the audioPlayer instance

    // Play the victory sound when the widget is displayed
    playVictorySound();

    // First, format the number with the US locale to get the correct decimal separator
    String tempFormattedPrizePoolAmount =
        NumberFormat('#,##0.##', 'en_US').format(prizePoolAmount);

// Then replace commas with dots for the thousand separator
    String formattedPrizePoolAmount =
        tempFormattedPrizePoolAmount.replaceAll(',', '.');
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // Close on tap
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent.shade200, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Color.fromARGB(150, 0, 0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'You have won ',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      TextSpan(
                        text: '$formattedPrizePoolAmount ',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                      ),
                      const TextSpan(
                        // ignore: unnecessary_string_escapes
                        text: '\Ƶ\$!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        25.0), // Match the button's border radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade200.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      // Adjust padding around the button text here
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0), // Add horizontal padding
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'WUAU! OK?!!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoseOverlay() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // Close on tap
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade200,
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_very_dissatisfied,
                    size: 48, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'Try Again!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextButton(
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerDataWidget extends StatefulWidget {
  final double conversionRatio;

  const PlayerDataWidget({super.key, required this.conversionRatio});

  @override
  PlayerDataWidgetState createState() => PlayerDataWidgetState();
}

class PlayerDataWidgetState extends State<PlayerDataWidget> {
  Map<String, dynamic> playerData = {};
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
    _loadUserEmail();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    String? playerDataString = prefs.getString('playerData');
    if (playerDataString != null) {
      Map<String, dynamic> tempPlayerData = jsonDecode(playerDataString);

      // Ensuring 'total_win_amount' is treated as a double
      if (tempPlayerData.containsKey('total_win_amount')) {
        var totalWinAmount = tempPlayerData['total_win_amount'];
        // Convert to double if it is not already
        tempPlayerData['total_win_amount'] =
            totalWinAmount is int ? totalWinAmount.toDouble() : totalWinAmount;
      }

      setState(() {
        playerData = tempPlayerData;
      });
    }
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
  }

  void _showAchievements() async {
    await GamesServices.showAchievements();
  }

  void _showLeaderboard() async {
    await GamesServices.showLeaderboards(); // Use your actual leaderboard ID
  }

  @override
  Widget build(BuildContext context) {
    // Assuming playerData['total_win_amount'] and conversionRatio are correctly fetched/set
    // Assuming playerData is a map

    final double totalWinAmount =
        (playerData['total_win_amount'] as double?) ?? 0.1;

// Calculate the initial real money value
    final double conversionRatio =
        widget.conversionRatio; // Default to 0.0 if not provided
    final double initialRealMoneyValue =
        (totalWinAmount * conversionRatio) * 0.60; // Adjusted formula

// Calculate 60% of the initial real money value
    final double realMoneyValue = initialRealMoneyValue;
    List<String> lastGuesses =
        playerData['last_guesses']?.toString().split(',') ?? [];

    return Material(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _showAchievements,
                    child: const Text('Achievements'),
                  ),
                  ElevatedButton(
                    onPressed: _showLeaderboard,
                    child: const Text('Leaderboard'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FutureBuilder<String>(
                      future: translator.translate("Wins"),
                      builder: (context, snapshot) => _buildHighlightedInfo(
                          title: snapshot.data ?? "Wins",
                          value: playerData['wins']?.toString() ?? '0'),
                    ),
                    FutureBuilder<String>(
                      future: translator.translate("Total Guesses"),
                      builder: (context, snapshot) => _buildHighlightedInfo(
                          title: snapshot.data ?? "Total Guesses",
                          value:
                              playerData['total_guesses']?.toString() ?? '0'),
                    ),
                  ],
                ),
              ),
              if (userEmail != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FutureBuilder<String>(
                    future: translator.translate("Logged in as"),
                    builder: (context, snapshot) {
                      String loggedInText = snapshot.data ?? "Logged in as";
                      return Text(
                        "$loggedInText: $userEmail",
                        style: const TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic),
                      );
                    },
                  ),
                ),
              FutureBuilder<String>(
                future: translator.translate("Earnings"),
                builder: (context, snapshot) =>
                    _buildSectionTitle(snapshot.data ?? "Earnings"),
              ),
              FutureBuilder<String>(
                future: translator.translate("Total Win Amount"),
                builder: (context, snapshot) => _buildAmountRow(
                    snapshot.data ?? "Total Win Amount:", totalWinAmount,
                    leadingIcon: Icons.account_balance_wallet),
              ),
              FutureBuilder<String>(
                future: translator.translate("Real Money Value"),
                builder: (context, snapshot) => _buildAmountRowWithExplanation(
                    snapshot.data ?? "Real Money Value:", realMoneyValue,
                    leadingIcon: Icons.monetization_on, isCurrency: true),
              ),
              const Divider(),
              FutureBuilder<String>(
                future: translator.translate("Highest Win"),
                builder: (context, snapshot) =>
                    _buildSectionTitle(snapshot.data ?? "Highest Win"),
              ),
              FutureBuilder<String>(
                future: translator.translate("Highest Win Amount"),
                builder: (context, snapshot) => _buildAmountRow(
                    snapshot.data ?? "Highest Win Amount:", totalWinAmount,
                    leadingIcon: Icons.emoji_events),
              ),
              const Divider(),
              FutureBuilder<String>(
                future: translator.translate("Last Guesses"),
                builder: (context, snapshot) =>
                    _buildSectionTitle(snapshot.data ?? "Last Guesses"),
              ),
              lastGuesses.isNotEmpty
                  ? Column(
                      children: lastGuesses
                          .map((guess) => ListTile(
                                leading: const Icon(Icons.casino,
                                    color: Colors.orange),
                                title: Text(guess,
                                    style: const TextStyle(fontSize: 16)),
                              ))
                          .toList(),
                    )
                  : FutureBuilder<String>(
                      future: translator.translate("No last guesses available"),
                      builder: (context, snapshot) => Text(
                          snapshot.data ?? "No last guesses available",
                          style: const TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRowWithExplanation(String title, double amount,
      {bool isCurrency = false, IconData? leadingIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountRow(title, amount,
            isCurrency: isCurrency, leadingIcon: leadingIcon),
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            "current revenue + your score * your total win amount",
            style: TextStyle(
              fontFamily: 'Proxima',
              fontSize: 12, // Adjust the size as needed
              fontStyle:
                  FontStyle.italic, // Use italic for the explanation if desired
              color: Colors
                  .grey, // Use a subtle color to indicate this is an explanation
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedInfo({required String title, required String value}) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildAmountRow(String title, double amount,
      {bool isCurrency = false, IconData? leadingIcon}) {
    return ListTile(
      leading: leadingIcon != null ? Icon(leadingIcon) : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        isCurrency
            ? '\$${amount.toStringAsFixed(2)}'
            : '${amount.toString()} Coins',
        style: const TextStyle(
            color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
// Assuming PlayerDataWidget is defined elsewhere in your code

class StatisticsFloatingButton extends StatefulWidget {
  final double conversionRatio; // Add conversionRatio as a field

  const StatisticsFloatingButton({
    super.key,
    required this.conversionRatio, // Require it as a named parameter
  });

  @override
  State<StatisticsFloatingButton> createState() =>
      _StatisticsFloatingButtonState();
}

class _StatisticsFloatingButtonState extends State<StatisticsFloatingButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  bool isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _toggleOverlay(BuildContext context) {
    if (isOverlayVisible) {
      _hideOverlay();
    } else {
      _showOverlay(context);
    }
  }

  void _showOverlay(BuildContext context) {
    _overlayEntry = _createOverlayEntry(context);
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    isOverlayVisible = true;
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((value) => _overlayEntry?.remove());
      isOverlayVisible = false;
    }
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    // Animation for slide transition
    var slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0), // Start from the right
      end: Offset.zero, // End at its natural position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Tracking start and end points of the swipe
    Offset? dragStart;
    Offset? dragEnd;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideOverlay, // Close drawer when tapping outside
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Transparent area
            Positioned.fill(
              child: Container(
                  color: Colors.black54), // Semi-transparent background
            ),
            // Drawer
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: slideAnimation,
                child: Material(
                  elevation: 16.0, // Shadow
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: GestureDetector(
                      onHorizontalDragStart: (details) {
                        dragStart = details.globalPosition;
                      },
                      onHorizontalDragUpdate: (details) {
                        dragEnd = details.globalPosition;
                      },
                      onHorizontalDragEnd: (details) {
                        // Determine swipe direction and velocity
                        final velocity = details.primaryVelocity ?? 0;
                        // Close drawer if swipe to the right or fast swipe to the left
                        if (dragEnd!.dx > dragStart!.dx || velocity > 250) {
                          _hideOverlay();
                        }
                      },
                      child: Column(
                        children: [
                          AppBar(
                            title: const Text("Player Stats"),
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed:
                                  _hideOverlay, // Back button to close the drawer
                            ),
                            automaticallyImplyLeading: false,
                          ),
                          Expanded(
                            child: PlayerDataWidget(
                                conversionRatio: widget
                                    .conversionRatio), // Use widget.conversionRatio here
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _toggleOverlay(context),
      child: Icon(isOverlayVisible ? Icons.close : Icons.bar_chart),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
