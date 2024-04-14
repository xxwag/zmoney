// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math; // Import the math library
import 'dart:math';

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
import 'package:zmoney/fukk_widgets/ad_service.dart';
import 'package:zmoney/fukk_widgets/app_assets.dart';
import 'package:zmoney/fukk_widgets/language_selector.dart';
import 'package:zmoney/fukk_widgets/number_input.dart';
import 'package:zmoney/fukk_widgets/play_google.dart';
import 'package:zmoney/fukk_widgets/skin.dart';
import 'package:zmoney/fukk_widgets/statistics_playerdata.dart';
import 'package:zmoney/fukk_widgets/translator.dart';
import 'package:zmoney/fukk_widgets/ngrok.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:zmoney/side_menu.dart';
import 'package:zmoney/fukk_widgets/text_cycle.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

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
  final bool _isRewardedAdReady = false;
// Add a new boolean to track if the timer has finished.
  bool _timerFinished = false;
  bool _isBannerAdReady = false;
// State to manage tutorial visibility
// State for party animation
  final TextEditingController _numberController = TextEditingController();

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

  List<String> translatedTexts = []; // Make it an empty, growable list

  late Future<List<Skin>> futureSkins; // To store the future list of skins

  double _prizePoolAmount = 100000; // Starting amount
  double _conversionRatio = 0.1; // Adjusted for demonstration

// To track the Go button lock state
  bool isButtonLocked = false; // Add this variable to your widget state

  final bool _isGreenText = true; // Define _isGreenText as a boolean variable

// Default color, can be black or white

  Duration animationDuration = const Duration(seconds: 5);

  bool useTexture = false; // Flag to toggle between color and texture
  int currentSkin = 1; // Default skin. Adjust based on how many skins you have.
  int currentSkinIndex = 0; // Default to the first skin

  List<Skin> skins = [];

  late Directory directory; // To hold the application directory path
  final AdService _adService = AdService();

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _preventAd =
      false; // Flag to prevent ad from showing on consecutive guesses
  bool _arrowsVisible = true;
  late AnimationController _glowController; // Renamed for clarity
  late Animation<double> _glowAnimation; // Renamed for clarity

  bool _isLoading = true;
  // In your LandingPageState class
  double _initializationProgress =
      0.0; // Progress of initialization (0.0 to 1.0)
  final List<String> _progressMessages =
      []; // Messages to display during initialization

  //INIT STATE <<<<<<<<<<<<<<<<<<<<

  @override
  void initState() {
    super.initState();

    AdService().initBannerAd(
      onBannerAdLoaded: () {
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onBannerAdFailedToLoad: () {
        setState(() {
          _isBannerAdReady = false;
        });
      },
    );
    AdService().loadRewardedAd(
      onRewardedAdLoaded: () {
        // Here, you can set state or perform other actions upon successful loading.
      },
      onRewardedAdFailedToLoad: () {
        // Handle the failure of ad loading.
      },
    );
    AdService().loadRewardedInterstitialAd();
    _initializeAsyncOperations().then((_) {
      _checkLastGuessTimeAndStartTimerIfNeeded();
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading to false when done
        });
      }
    });
    WidgetsBinding.instance.addObserver(this); // Add the observer
  }

  Future<void> _initializeAsyncOperations() async {
    // Assume there are 5 steps in total
    double progressIncrement = 1.0 / 6;

    // Update the progress and message for each step
    await _initSkinsAndDirectory();
    _updateProgress(progressIncrement, "Initialized skins and directories");
    await checkAndFetchAssets();
    _updateProgress(progressIncrement, "Assets checked and fetched");

    initializeTranslations();
    _updateProgress(progressIncrement, "Translations initialized");

    await _fetchPrizePoolFromServer();
    _updateProgress(progressIncrement, "Fetched prize pool from server");

    await _loadCurrentSkinIndex();
    _updateProgress(progressIncrement, "Loading current skin");

    _confettiController = ConfettiController();
    _glowController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(_glowController);
    _glowController.repeat(reverse: true);
    _updateProgress(progressIncrement, "Controllers initialized");

    await VideoPlayerManager().init();
    _updateProgress(progressIncrement, "Video player manager initialized");

    // When all tasks are completed, ensure progress is set to 100%
    if (_initializationProgress < 1.0) {
      setState(() {
        _initializationProgress = 1.0;
        _isLoading = false; // Hide loading indicator and show content
      });
    }
  }

  Future<void> _checkLastGuessTimeAndStartTimerIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGuessTimeMillis = prefs.getInt('lastGuessTime');

    if (lastGuessTimeMillis != null) {
      final lastGuessTime =
          DateTime.fromMillisecondsSinceEpoch(lastGuessTimeMillis);
      final currentTime = DateTime.now();
      final differenceInSeconds =
          currentTime.difference(lastGuessTime).inSeconds;

      const tenMinutesInSeconds = 10 * 60;
      if (differenceInSeconds < tenMinutesInSeconds) {
        setState(() {
          _remainingTime = tenMinutesInSeconds - differenceInSeconds;
          _timerStarted = true;
          isButtonLocked = true;
        });
        startTimer(); // Start the timer based on the calculated remaining time
      }
    }
  }

  Future<void> _loadCurrentSkinIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSkinIndex = prefs.getInt('currentSkinIndex');
    if (savedSkinIndex != null &&
        savedSkinIndex >= 0 &&
        savedSkinIndex < skins.length) {
      setState(() {
        currentSkinIndex = savedSkinIndex;
      });
    }
    // Optionally, handle the case where skins haven't been initialized yet
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Only initialize or load ads when the app resumes to avoid unnecessary memory usage
      _isBannerAdReady
          ? null
          : AdService().initBannerAd(
              onBannerAdLoaded: () {
                setState(() {
                  _isBannerAdReady = true;
                });
              },
              onBannerAdFailedToLoad: () {
                setState(() {
                  _isBannerAdReady = false;
                });
              },
            ); // Conditional loading
      _isRewardedAdReady
          ? null
          : AdService().loadRewardedAd(
              onRewardedAdLoaded: () {
                // Here, you can set state or perform other actions upon successful loading.
              },
              onRewardedAdFailedToLoad: () {
                // Handle the failure of ad loading.
              },
            ); // Conditional loading
      _fetchPrizePoolFromServer();
    }
  }

  // Function to handle the press of the ad button
  void _onPressAdButton() {
    // Close the keyboard
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 300), () {
      AdService().showRewardedAd(
        onRewardedAdSuccess: unlockButtonAndStopTimer,
        onRewardedAdFailedToShow: () {
          // Handle the ad failed to show scenario
        },
        onRewardedAdDismissed: () {
          // Handle the ad dismissed scenario
        },
      );
    });
  }

  void unlockButtonAndStopTimer() {
    if (mounted) {
      setState(() {
        isButtonLocked = false; // Unlock the "Go" button
        _timer?.cancel(); // Stop the timer
        _timerStarted = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _rewardedInterstitialAd?.dispose();
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void _updateProgress(double increment, String message) {
    setState(() {
      _initializationProgress += increment;
      _progressMessages.add(message);
      // Optionally, you might only want to show the latest message
      // _progressMessages = [message];
    });
  }

  Future<void> _initSkinsAndDirectory() async {
    directory = await getApplicationDocumentsDirectory(); // Sets the directory
    List<dynamic> inventory = await _loadInventory(); // Load inventory
    skins = await _createSkins(inventory); // Create skins based on inventory
    setState(() {}); // Trigger rebuild with initialized skins
  }

  Future<List<Skin>> _createSkins(List<dynamic> inventory) async {
    List<String> inventoryIds =
        inventory.map((item) => item['productId'].toString()).toList();

    List<Skin> allSkins = [
      // Default skin always available
      Skin(
        id: "defaultSkin", // Example ID
        isAvailable: true, // Default skins can be available by default
        overlayButtonColor1: Colors.white,
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
        id: "spidermanSkin", // Unique ID for the Spiderman skin
        isAvailable: true, // Assuming this skin is available for users
        overlayButtonColor1: Colors.white,
        backgroundColor:
            Colors.blue[800]!, // Dark blue, reminiscent of Spiderman's suit
        prizePoolTextColor: Colors.red[
            600]!, // Vibrant red for highlights, evoking Spiderman's primary color
        textColor: Colors
            .white, // High contrast white for readability, similar to Spiderman's eye lenses
        specialTextColor: Colors
            .yellow, // Vibrant red for special texts, matching Spiderman's color theme
        buttonColor: Colors.red[
            800]!, // Darker red for buttons, keeping in theme with Spiderman's suit
        buttonTextColor:
            Colors.yellow, // White text for clear readability on buttons
        textColorSwitchTrue: Colors.blue[
            300]!, // Light blue for the true state, complementing the suit's blue
        textColorSwitchFalse: Colors.red[
            300]!, // Light red for the false state, complementing the suit's red
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File('${directory.path}/textures/spiderman.jpg')),
            fit: BoxFit.cover,
          ),
        ),
      ),

      Skin(
        id: "Iceland", // Example ID
        isAvailable: true, // Default skins can be available by default
        overlayButtonColor1: Colors.white,
        backgroundColor: Colors.white,
        prizePoolTextColor: Colors.blueAccent,
        textColor: Colors.black,
        specialTextColor: Colors.white, // Example special text color
        buttonColor: Colors.white,
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
        id: "Forest", // Example ID
        isAvailable: true, // Default skins can be available by default

        overlayButtonColor1: Colors.white,
        backgroundColor: const Color(0xFF0B3D2E), // Dark Green
        prizePoolTextColor: Colors.white, // Bright Green
        textColor: Colors.white, // Light Beige
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
        id: "Wood", // Example ID
        isAvailable: true, // Default skins can be available by default
        backgroundColor: Colors.white, // Deep wood color

        overlayButtonColor1: Colors.white,
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
      // Other skins with conditional availability
      Skin(
        id: "emerald", // Example ID
        isAvailable: inventoryIds.contains("emeraldskin"),

        overlayButtonColor1: Colors.white,
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

      // Repeat for other skins...
    ];

    // Filter skins based on the isAvailable flag
    List<Skin> availableSkins =
        allSkins.where((skin) => skin.isAvailable).toList();

    return availableSkins; // Return the filtered list of skins
  }

  Future<List<dynamic>> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? inventoryJson = prefs.getString('inventory');
    if (inventoryJson != null) {
      return jsonDecode(inventoryJson) as List<dynamic>;
    }
    return [];
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
      'Zmoney Store',
      'Watch ad to guess again right now!',
      'Call Pranker'
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
    });
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

  void _toggleSkin(bool isIncrementing) async {
    PlayGoogle.unlockAchievement("CgkIipShgv8MEAIQDg");
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

    // Save the currentSkinIndex to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentSkinIndex', currentSkinIndex);
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool isBannerAdReady = _adService.isBannerAdReady;

    // Check if the skins list is empty. If so, display a placeholder or loading indicator.
    if (skins.isEmpty) {
      return CircularProgressIndicator(); // Or a Placeholder widget
    }

// Use the currentSkinIndex to get the current Skin object

    // Safely access the skins list knowing it's not empty
    Skin currentSkin = skins[currentSkinIndex];

    // Calculate maxBlastForce based on screen width, with a maximum limit
    double calculatedBlastForce = screenSize.width / 1; // Example calculation
    double maxAllowedBlastForce = 1800; // Set your maximum limit here
    double maxBlastForce = math.min(calculatedBlastForce, maxAllowedBlastForce);
    final bannerAdHeight = isBannerAdReady
        ? 50.0
        : 0.0; // Example ad height, adjust based on actual ad size

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/mainscreen.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _initializationProgress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.lightBlueAccent),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: Text(
                    _progressMessages.isNotEmpty
                        ? _progressMessages.last
                        : "Initializing...",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Optional: Add a visual element like a Flutter logo or another relevant image
                const Opacity(
                  opacity: 0.8,
                  child: FlutterLogo(size: 100),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Your existing build code for the main content goes here
    return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: SideMenuDrawer(
            translatedTexts: translatedTexts,
            containerColor: currentSkin.overlayButtonColor1,
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

                      if (isBannerAdReady)
                        Positioned(
                          top: 40, // Banner ad at the top
                          child: Center(
                            child: ClipRect(
                              // Clip to prevent overflow
                              child: SizedBox(
                                width: screenSize.width,
                                height:
                                    bannerAdHeight, // Adjust based on actual ad size
                                child: AdWidget(ad: _adService.bannerAd!),
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        top: 33 +
                            (isBannerAdReady
                                ? bannerAdHeight
                                : 40), // Dynamically adjust based on ad readiness
                        left: 20,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: Icon(Icons.menu,
                                color: currentSkin.overlayButtonColor1,
                                size: 30.0),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),

                      // Marquee Text Positioned
                      /*  if (!isKeyboardOpen)
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
                        ),*/
                      if (!isKeyboardOpen)
                        // Only show the prize pool counter if the keyboard is not open
                        _buildPrizePoolCounter(isKeyboardOpen),

                      Container(
                        alignment: Alignment
                            .bottomRight, // Keep the button aligned to the bottom right
                        child: Transform.translate(
                          offset: Offset(15,
                              15), // Now pushing it to the opposite direction
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors
                                  .transparent, // Container color: Transparent or match your background
                              borderRadius: BorderRadius.circular(
                                  15), // Adjust for desired roundness
                            ), // Adjust these values to push the button partially off-screen
                            child: StatisticsFloatingButton(
                              conversionRatio: _conversionRatio,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 33 +
                            (isBannerAdReady
                                ? bannerAdHeight
                                : 40), // Dynamically adjust based on ad readiness
                        right: 20,
                        child: LanguageSelectorWidget(
                          onLanguageChanged: (String newLanguageCode) {
                            initializeTranslations();
                          },
                          dropdownColor: currentSkin.buttonColor,
                          textColor: currentSkin
                              .overlayButtonColor1, // Custom text color
                          iconColor: currentSkin
                              .overlayButtonColor1, // Custom icon color
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
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Centers the children horizontally
                                    children: <Widget>[
                                      IconButton(
                                        icon: Icon(Icons.chevron_left,
                                            size: 60,
                                            color: currentSkin.specialTextColor
                                                .withOpacity(
                                                    _glowAnimation.value)),
                                        onPressed: () => _toggleSkin(false),
                                      ),
                                      Expanded(
                                        // This makes the text widget flexible in the row, taking up the remaining space
                                        child: Center(
                                          // Explicitly center the AutoSizeText horizontally
                                          child: AutoSizeText(
                                            translatedTexts[15],
                                            minFontSize: 12,
                                            maxFontSize: 16,
                                            style: TextStyle(
                                              fontFamily: 'Proxima',
                                              fontWeight: FontWeight.w700,
                                              color: currentSkin
                                                  .specialTextColor
                                                  .withOpacity(
                                                      _glowAnimation.value),
                                              fontSize: 20,
                                              shadows: [
                                                Shadow(
                                                  offset:
                                                      const Offset(0.0, 0.0),
                                                  blurRadius: 12.0,
                                                  color: currentSkin
                                                      .specialTextColor
                                                      .withOpacity(
                                                          _glowAnimation.value),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow
                                                .ellipsis, // Add an overflow rule if needed
                                          ),
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
                                  ));
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
                                      Center(
                                        child: NumberInputField(
                                          controller: _numberController,
                                          screenSize:
                                              MediaQuery.of(context).size,
                                          hintText: translatedTexts[1],
                                          primaryColor: currentSkin
                                              .textColor, // Example primary color
                                          secondaryColor:
                                              currentSkin.backgroundColor,
                                          thirdColor:
                                              currentSkin.prizePoolTextColor,
                                          fifthColor: currentSkin
                                              .buttonColor, // Example secondary color
                                        ),
                                      ),
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
                                      if (_timerStarted)
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
                                                  translatedTexts[21],
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1); // Adjusted from 5 to 1 second
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
        setState(() {
          _remainingTime = secondsLeft;
        });
      }
    });
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
    double bottomPosition = keyboardOpen ? 100 : 20;

    Skin currentSkin = skins[currentSkinIndex];
    return Positioned(
      bottom: bottomPosition,
      left: 0,
      right: 0,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = MediaQuery.of(context).size.width;
            double pillWidth = min(screenWidth * 0.8, 200);
            double textHeight = 24;
            double pillHeight = textHeight * 2;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  translatedTexts[16],
                  style: TextStyle(
                    fontFamily: 'Proxima',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedFlipCounter(
                            prefix: "ⓩ ",
                            //suffix: " ,-",
                            thousandSeparator:
                                '.', // Specify the separator here
                            duration: const Duration(seconds: 5),
                            value: _prizePoolAmount, // Keep this as numeric
                            textStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: currentSkin.prizePoolTextColor,
                              fontFamily: 'Digital-7',
                              shadows: [
                                Shadow(
                                  offset: const Offset(-1.5, -1.5),
                                  color: currentSkin.prizePoolTextColor
                                      .withOpacity(0.2),
                                ),
                                Shadow(
                                  offset: const Offset(1.5, 1.5),
                                  color: currentSkin.prizePoolTextColor
                                      .withOpacity(0.2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> submitGuess() async {
    String guessStr = _numberController.text;

    if (guessStr.isEmpty) {
      _showEmptyTextFieldNotification();
      return;
    }

    if (guessStr.length < 4) {
      // Call the unlockAchievement method
      PlayGoogle.unlockAchievement("CgkIipShgv8MEAIQDw");
    } else {
      PlayGoogle.unlockAchievement("CgkIipShgv8MEAIQEA");
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
    // Store the last guess time in SharedPreferences
    int currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('lastGuessTime', currentTimeMillis);

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

        double prizePoolAmount =
            _prizePoolAmount.toDouble(); // Assuming this is already a double

        // Update guess count and potentially other fields based on guess correctness
        // Update guess count and potentially other fields based on guess correctness
        int totalGuesses = (playerData['total_guesses'] ?? 0) + 1;
        playerData['total_guesses'] = totalGuesses;

// If total guesses are exactly 10, unlock an achievement
        if (totalGuesses > 10) {
          PlayGoogle.unlockAchievement("CgkIipShgv8MEAIQCg");
        }

        if (isCorrect) {
          PlayGoogle.unlockAchievement('CgkIipShgv8MEAIQCA');
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
        await AdService().showRewardedInterstitialAd();
      } else {
        // If an ad was shown last time, reset the flag to allow showing ads again
        if (_preventAd) {
          _preventAd = false;
        }
      }
      _showServerNotRunningDialog();
    }
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
    appDocumentsDirectory ??= await getApplicationDocumentsDirectory();

    // Directly construct the path using appDocumentsDirectory
    final soundFilePath =
        p.join(appDocumentsDirectory!.path, 'sounds/victory_sound.mp3');

    if (await File(soundFilePath).exists()) {
      await audioPlayer.play(DeviceFileSource(soundFilePath));
    } else {
      // Handle the case where the file doesn't exist as needed
    }
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
