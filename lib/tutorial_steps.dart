import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math; // Import the math library
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zmoney/marquee.dart';
import 'package:zmoney/ngrok.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:zmoney/side_menu.dart';
import 'package:zmoney/tutorial_steps.dart';
// Import the necessary library

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  Timer? _timer;
  DateTime? lastPressed;
  int _remainingTime = 600;
  late bool _timerStarted = false;
  late BannerAd _bannerAd;

  bool _isBannerAdReady = false;
  bool _showTutorial = true; // State to manage tutorial visibility
  bool _showPartyAnimation = true; // State for party animation
  final TextEditingController _numberController = TextEditingController();
  late TutorialManager tutorialManager;

  bool _isWaitingForResponse = false;

  int _tutorialStep = 0; // To keep track of tutorial steps
  late ConfettiController _confettiController; // ConfettiController
  int randomAnimationType = 1; // Default to 1 or any valid animation type
  // GlobalKeys for target widgets
  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey keyLanguageSelector = GlobalKey();
  // Add more keys as needed
  String _selectedLanguageCode = 'en'; // Default language code

  List<String> translatedTexts =
      List.filled(15, '', growable: false); // Expanded to 15

  String translatedText1 = 'How Much?';
  String translatedText2 = 'Enter numbers';
  String translatedText3 = 'Go!';
  String translatedText4 = 'Ready';
  String translatedText5 = 'The next try will be available in:';
  String translatedText6 = 'This is the Go button. Tap here to start.';
  String translatedText7 = 'Tap the Go button to start your journey!';
  String translatedText8 = 'Here you can enter numbers.';
  String translatedText9 = 'Enter numbers in this field.';
  String translatedText10 = 'Select your language';
  String translatedText11 = 'Game Menu';
  String translatedText12 = 'How to play: Enter numbers & test your luck.';
  String translatedText13 = 'You can win various prices, including real money.';
  String translatedText14 = 'Account inventory';
  String translatedText15 = 'Settings';

  double _prizePoolAmount = 100000; // Starting amount

  bool _isGoButtonLocked = false; // To track the Go button lock state
  bool isButtonLocked = false; // Add this variable to your widget state

  List<TutorialStep> tutorialSteps = [];

  Color _currentColor = Colors.black; // Default color, can be black or white

  List<Color> colorSequence = [
    const Color(0xFF2196F3), // Bright Blue
    const Color(0xFF64B5F6), // Light Blue (Transition)
    const Color(0xFF4CAF50), // Green
    const Color(0xFF81C784), // Light Green (Transition)
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFFD54F), // Light Amber (Transition)
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFFFF8A65), // Light Orange (Transition)
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFCE93D8), // Light Purple (Transition)
    const Color(0xFFE91E63), // Pink
    const Color(0xFFF48FB1), // Light Pink (Transition)
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF80DEEA), // Light Cyan (Transition)
    const Color(0xFF2196F3), // Bright Blue (looping back)
  ];
  Duration animationDuration = const Duration(seconds: 5);

  int _currentColorIndex = 0;
  bool _isAnimating = false;

  void _incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    int launchCount = prefs.getInt('launchCount') ?? 0;
    prefs.setInt('launchCount', launchCount + 1);
  }

  //INIT STATE <<<<<<<<<<<<<<<<<<<<
  @override
  void initState() {
    super.initState();
    _increasePrizePool();
    NgrokManager.fetchNgrokData();
    fetchAndSetTranslations(_selectedLanguageCode);
    _incrementLaunchCount();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();

    // TADY SE MUSI DODELAT TUTORIAL STEPY, KAZDEJ JE NAVAZANEJ NA KEY (key1, key2) KTERYM SE MUSI OZNACIT ELEMENT WIDGETU
    // VIz. DOLE TUTORIAL STEP CLASS
    // Delayed call to adjust tutorial steps if necessary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          tutorialManager = TutorialManager(
            translatedTexts: translatedTexts,
            keys: [keyLanguageSelector, key1, key2],
          );
        });
      }
    });

    togglePartyAnimation();
    // Check if the tutorial has been completed previously
    _checkTutorialCompletion();
    _initBannerAd();
  }

  Future<bool> onWillPop() async {
    final now = DateTime.now();
    if (lastPressed == null ||
        now.difference(lastPressed!) > Duration(seconds: 2)) {
      lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Press back again to exit"),
          duration: Duration(seconds: 2),
        ),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

  void _restartTutorialIfNeeded() {
    if (_showTutorial) {
      // Reset tutorial steps with updated translations
      tutorialSteps = [
        TutorialStep(
          widget: _tutorialStepWidget("Select your preferred language here."),
          targetKey: keyLanguageSelector,
          direction: TooltipDirection.top,
          description: "This dropdown allows you to choose your language.",
        ),
        TutorialStep(
          widget: _tutorialStepWidget(translatedTexts[7]),
          targetKey: key1,
          direction: TooltipDirection.bottom,
          description: translatedTexts[8], // Add description
        ),
        TutorialStep(
          widget: _tutorialStepWidget(translatedTexts[6]),
          targetKey: key2,
          direction: TooltipDirection.top,
          description: translatedTexts[5], // Add description
        ),
      ];

      // Reset tutorial step and make tutorial visible
      setState(() {
        _tutorialStep = 0;
        _showTutorial = true;
      });
    }
  }

  void togglePartyAnimation() {
    int randomAnimationType = Random().nextInt(4) + 1;

    setState(() {
      _isAnimating = true;
    });

    switch (randomAnimationType) {
      case 1:
        animationType1();
        break;
      case 2:
        animationType2();
        break;
      case 3:
        animationType3();
        break;
      case 4:
        animationType4();
        break;
      default:
        break;
    }

    // Stop the animation after a specified duration
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void animationType1() {
    _isAnimating = true;
    cycleThroughColors();
  }

  void animationType2() {
    _isAnimating = true;
    fastBlinkBlackAndWhite();
  }

  void fastBlinkBlackAndWhite() {
    if (!_isAnimating) return;

    setState(() {
      _currentColor =
          (_currentColor == Colors.black) ? Colors.white : Colors.black;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      // Faster blink rate
      if (mounted && _isAnimating) {
        fastBlinkBlackAndWhite();
      }
    });
  }

  void animationType3() {
    _isAnimating = true;
    cycleThroughColorsReverse();
  }

  void cycleThroughColorsReverse() {
    if (!_isAnimating) return;

    setState(() {
      _currentColorIndex =
          (_currentColorIndex - 1).abs() % colorSequence.length;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isAnimating) {
        cycleThroughColorsReverse();
      }
    });
  }

  void animationType4() {
    _isAnimating = true;
    fastBlinkBlackAndWhite();
  }

  void cycleThroughColors() {
    if (!_isAnimating) return;

    setState(() {
      _currentColorIndex = (_currentColorIndex + 1) % colorSequence.length;
      _showPartyAnimation = !_showPartyAnimation; // Toggles the state
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isAnimating) {
        cycleThroughColors(); // Continue cycling through colors
      }
    });
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
    _confettiController.play();

    // Schedule the animation to stop after a certain duration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _confettiController.stop();
      }
    });
  }

  void startTimer() {
    if (_timer != null) {
      _timer!.cancel(); // Cancel any existing timer
    }

    if (!_isGoButtonLocked) {
      // Check if the Go button is not locked
      setState(() {
        _timerStarted = true;
        _remainingTime = 600; // 10 minutes in seconds
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          _timer!.cancel();

          // Unlock the Go button after the timer expires
          setState(() {
            _isGoButtonLocked = false;
          });
        }
      });
    }
  }

  Future<String> combineEnglishTextsForTranslation(
      SharedPreferences prefs) async {
    const separator = "999666"; // Unique separator
    List<String> texts = [];

    // Predefined list of default English texts
    List<String> defaultTexts = [
      translatedText1,
      translatedText2,
      translatedText3,
      translatedText4,
      translatedText5,
      translatedText6,
      translatedText7,
      translatedText8,
      translatedText9,
      translatedText10,
      translatedText11,
      translatedText12,
      translatedText13,
      translatedText14,
      translatedText15
    ];

    // Checking and creating SharedPreferences entries if they don't exist
    for (int i = 1; i <= defaultTexts.length; i++) {
      String key = 'translatedText$i' '_en'; // Corrected key format
      if (!prefs.containsKey(key)) {
        // If the key doesn't exist, set the default English text
        await prefs.setString(key, defaultTexts[i - 1]);
      }
      // Fetching the text from SharedPreferences
      String text = prefs.getString(key) ?? "Default Text $i";
      texts.add(text);
    }

    // After fetching, print each translated text
    for (int i = 0; i < texts.length; i++) {}

    return texts.join(separator);
  }

  Future<String> translateText(String text, String toLang,
      {String fromLang = 'auto'}) async {
    var url = Uri.parse('https://libretranslate.de/translate');
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "q": text,
          "source": fromLang,
          "target": toLang,
          "format": "text",
          "api_key": "" // Include the API key if you have one
        }),
      );

      if (response.statusCode == 200) {
        var decodedResponse =
            utf8.decode(response.bodyBytes); // Explicit UTF-8 decoding
        var data = json.decode(decodedResponse);
        return data['translatedText'];
      } else {
        return text; // Return original text on failure
      }
    } catch (e) {
      return text; // Return original text on error
    }
  }

  Future<void> fetchAndSetTranslations(String targetLanguageCode) async {
    final prefs = await SharedPreferences.getInstance();

    // Use the original English texts as a base for translation
    String combinedEnglishTexts =
        await combineEnglishTextsForTranslation(prefs);

    List<String> updatedTranslations = List.filled(15, '', growable: false);

    if (targetLanguageCode != 'en') {
      // Translate English texts to the target language
      String translatedCombinedTexts =
          await translateText(combinedEnglishTexts, targetLanguageCode);
      List<String> individualTranslations =
          translatedCombinedTexts.split("999666");

      // Ensure there are enough elements in the list
      for (int i = 0;
          i < individualTranslations.length && i < updatedTranslations.length;
          i++) {
        updatedTranslations[i] = individualTranslations[i].trim();
      }
    } else {
      // Use English texts directly
      for (int i = 0; i < updatedTranslations.length; i++) {
        updatedTranslations[i] = prefs.getString('translatedText${i + 1}_en') ??
            "Default Text ${i + 1}";
      }
    }

    // Update state with new translations
    setState(() {
      translatedTexts = updatedTranslations;
      // Initialize or update tutorialManager here
      tutorialManager = TutorialManager(
        translatedTexts: translatedTexts,
        keys: [keyLanguageSelector, key1, key2],
      );
    });
    _restartTutorialIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerAd.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildLanguageSelector() {
    Map<String, String> languages = {
      'en': 'English',
      'cs': 'Czechia',
      'fr': 'French',
      'zh': 'Chinese',
      'da': 'Danish',
      'nl': 'Dutch',
      'de': 'German',
      'el': 'Greek',
      'it': 'Italian',
      'ja': 'Japanese',
      'lt': 'Lithuanian',
      'nb': 'Norwegian Bokmål',
      'pl': 'Polish',
      'pt': 'Portuguese',
      'ro': 'Romanian',
      'es': 'Spanish',

      // Add other supported languages here
    };

    return DropdownButton<String>(
      key: keyLanguageSelector, // Assign the GlobalKey here
      value: _selectedLanguageCode,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? newValue) {
        if (newValue != null && newValue != _selectedLanguageCode) {
          setState(() {
            _selectedLanguageCode = newValue;
          });
          fetchAndSetTranslations(newValue); // Fetch new translations
        }
      },
      items: languages.entries.map<DropdownMenuItem<String>>((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
    );
  }

  void _increasePrizePool() {
    if (_prizePoolAmount < 1000000) {
      // Generate a random increase amount, you can adjust the range as needed
      int randomIncrease = Random().nextInt(500) + 100; // Between 100 and 600

      setState(() {
        _prizePoolAmount += randomIncrease; // Increment the amount unevenly
      });

      // Schedule the next update with a random delay
      int randomDelay = Random().nextInt(5) + 1; // Between 1 and 5 seconds
      Future.delayed(Duration(seconds: randomDelay), _increasePrizePool);
    }
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-4652990815059289/6968524603',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('Ad failed to load: $error');
          }
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  Widget _buildPrizePoolCounter(bool keyboardOpen) {
    double bottomPosition =
        keyboardOpen ? 100 : 20; // Adjust position based on keyboard visibility

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
            double pillHeight = textHeight + textHeight;

            return Column(
              // Wrap the existing Container in a Column
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Current Reward:", // Add the text here
                  style: TextStyle(
                    fontSize: 16, // Adjust the font size as needed
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Adjust the color as needed
                  ),
                ),
                const SizedBox(height: 8), // Add spacing between text and pill
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
                      // Outline
                      AnimatedFlipCounter(
                        duration: const Duration(milliseconds: 500),
                        value: _prizePoolAmount,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(0, 255, 255, 255),
                          fontFamily: 'Digital-7',
                          shadows: [
                            Shadow(
                                offset: Offset(-1.5, -1.5),
                                color: Color.fromARGB(0, 255, 255, 255)),
                            Shadow(
                                offset: Offset(1.5, 1.5),
                                color: Color.fromARGB(0, 255, 255, 255)),
                          ],
                        ),
                        prefix: "\$",
                      ),
                      // Main Text
                      AnimatedFlipCounter(
                        duration: const Duration(milliseconds: 500),
                        value: _prizePoolAmount,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontFamily: 'Digital-7',
                        ),
                        prefix: "\$",
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

  Color _determineContainerColor() {
    switch (randomAnimationType) {
      case 1:
      case 3:
        // For animation types 1 and 3, use the color sequence
        return colorSequence[_currentColorIndex];
      case 2:
      case 4:
        // For animation types 2 and 4, use the current color (black or white)
        return _currentColor;
      default:
        // Default color
        return Colors.transparent;
    }
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
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'Inter',
          ),
          onTap: _playConfettiAnimation, // Play confetti on interaction
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    Color containerColor =
        _determineContainerColor(); // Use the container color determining method

    // Calculate maxBlastForce based on screen width, with a maximum limit
    double calculatedBlastForce = screenSize.width / 1; // Example calculation
    double maxAllowedBlastForce = 1800; // Set your maximum limit here
    double maxBlastForce = math.min(calculatedBlastForce, maxAllowedBlastForce);

    return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          drawer: SideMenuDrawer(
            translatedTexts: translatedTexts,
            containerColor: containerColor,
          ),
          body: Column(children: [
            if (_isBannerAdReady)
              AnimatedContainer(
                duration: const Duration(
                    seconds: 2), // Duration of the color transition
                color:
                    containerColor, // This color will animate when containerColor changes
                child: SafeArea(
                  top: true, // Only apply padding at the top
                  child: SizedBox(
                    width: screenSize.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
                ),
              ),

            // The rest of the content is in an Expanded widget
            Expanded(
              child: Stack(
                children: [
                  // Animated background container
                  AnimatedContainer(
                    duration: const Duration(seconds: 2),
                    color: containerColor,
                    width: screenSize.width,
                    height: screenSize.height,
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
                      numberOfParticles: 13,
                      gravity: 0.01,
                      colors: const [Colors.green],
                      minBlastForce: 1,
                      maxBlastForce:
                          maxBlastForce, // Ensure this is defined in your state
                    ),
                  ),

                  Positioned(
                    top: 20,
                    left: 20,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, size: 30.0),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildLanguageSelector(),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: screenSize.height * 0.05),
                                if (!isKeyboardOpen)
                                  Text(
                                    translatedTexts[0], // Use translated text
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                SizedBox(height: screenSize.height * 0.1),
                                _buildNumberInput(
                                    screenSize, translatedTexts[1]),
                                SizedBox(height: screenSize.height * 0.1),
                                _buildGoButton(screenSize, translatedTexts[2],
                                    isButtonLocked),
                                SizedBox(height: screenSize.height * 0.025),
                                Text(
                                  _timerStarted
                                      ? '${translatedTexts[4]} ${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
                                      : translatedTexts[
                                          3], // Assuming translatedText4 corresponds to index 3 in translatedTexts
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Marquee Text Positioned
                  if (!isKeyboardOpen)
                    Positioned(
                      bottom: -10, // Adjust as needed
                      child: SizedBox(
                        width: screenSize.width,
                        height: 40, // Adjust the height as needed
                        child: MarqueeText(
                          text: '⚠️App still in the development!         ' * 20,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5), // 50% opacity
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!isKeyboardOpen)
                    // Only show the prize pool counter if the keyboard is not open
                    _buildPrizePoolCounter(isKeyboardOpen),

                  tutorialManager?.isTutorialActive ?? false
                      ? tutorialManager!.buildTutorialOverlay()
                      : const SizedBox.shrink(),
                ],
              ),
            )
          ]),
        ));
  }

  Widget _buildGoButton(Size screenSize, String buttonText, bool isLocked) {
    // Define the default and loading button colors
    const defaultColor = Colors.blue; // Change to your desired default color
    const loadingColor = Colors.grey; // Change to your desired loading color

    // Determine the button color based on the lock state
    final buttonColor = isLocked ? loadingColor : defaultColor;

    return GestureDetector(
      onTap: () {
        if (!_isWaitingForResponse && !_timerStarted && !isLocked) {
          // Check if the button is not locked
          submitGuess();
        }
      },
      child: Container(
        key: key2, // Assign the GlobalKey here
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          // Use the determined button color
          color: buttonColor,
        ),
        child: _isWaitingForResponse
            ? const CircularProgressIndicator()
            : Text(
                buttonText, // Use the translated text
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Future<void> submitGuess() async {
    // Fetch Ngrok data
    NgrokManager.fetchNgrokData();
    String guessStr = _numberController.text; // Guess as a string

    if (guessStr.isNotEmpty &&
        NgrokManager.ngrokUrl.isNotEmpty &&
        !_timerStarted) {
      setState(() {
        _isWaitingForResponse = true; // Start waiting stage
      });

      // Convert string to integer
      int? guessInt = int.tryParse(guessStr);
      if (guessInt == null) {
        if (kDebugMode) {
          print('Invalid number entered');
        }
        setState(() {
          _isWaitingForResponse = false;
        });
        return;
      }

      // Debug print for converted guess

      try {
        var response = await http.post(
          Uri.parse('${NgrokManager.ngrokUrl}/api/guess'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'guess': guessInt}), // Send the integer guess
        );

        // Debug prints for response

        if (response.statusCode == 200) {
          var result = json.decode(response.body);
          bool isCorrect = result['correct'];

          // Debug print for result

          // Handle the result
          setState(() {
            _isWaitingForResponse = false; // Stop waiting stage
            // Show result to user (win/lose)
            _showResultDialog(isCorrect);

            // Lock the "Go" button for the next 10 minutes
            isButtonLocked = true;

            // Start the 10-minute timer
            startTimer();
          });
        } else {
          // Handle non-200 responses
          setState(() {
            _isWaitingForResponse = false; // Stop waiting stage
          });
        }
      } catch (e) {
        // Handle exception
        setState(() {
          _isWaitingForResponse = false; // Stop waiting stage
        });

        if (e is SocketException || e is HttpException) {
          _showServerNotRunningDialog();
        }
      }
    } else {
      _showServerNotRunningDialog();
    }
  }

  void _showServerNotRunningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable closing by tapping outside
      builder: (BuildContext context) {
        bool isCheckingServer =
            true; // Local variable to track the checking process
        Timer? timer;

        // Function to periodically check server availability
        void checkServerAvailability() {
          timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
            try {
              final response = await http.get(Uri.parse(NgrokManager.ngrokUrl));
              if (response.statusCode == 200) {
                isCheckingServer = false;
                (context as Element)
                    .markNeedsBuild(); // Request a rebuild of the dialog
                t.cancel();
              }
            } catch (_) {
              // If there is an error, it means the server is not available yet.
            }
          });
        }

        // Start checking for server availability
        checkServerAvailability();

        return PopScope(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor:
                    Colors.transparent, // Make dialog background transparent
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent
                        .withOpacity(0.9), // Semi-transparent background
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius:
                            20, // Increased for a more pronounced glow effect
                        spreadRadius: 10, // Adjust spread for the glow size
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedCrossFade(
                        firstChild:
                            const CircularProgressIndicator(), // Show loading indicator
                        secondChild: const Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.white), // Show checkmark
                        crossFadeState: isCheckingServer
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCheckingServer
                            ? 'Checking server availability...'
                            : 'Server is now available!',
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
                          timer
                              ?.cancel(); // Stop the timer when dialog is closed
                          Navigator.of(context).pop(); // Close the dialog
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
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Disable closing by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          child: isCorrect ? _buildWinOverlay() : _buildLoseOverlay(),
        );
      },
    );
  }

  Widget _buildWinOverlay() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // Close on tap
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200,
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'Congratulations!',
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

  void _checkTutorialCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialCompleted = prefs.getBool('tutorialCompleted') ?? false;

    if (tutorialCompleted) {
      // Tutorial was completed previously, reset it
      await prefs.setBool('tutorialCompleted', false); // Reset to false
      setState(() => _showTutorial = true); // Show the tutorial again
    } else {
      // Tutorial was not completed, keep the current state
      setState(() => _showTutorial = false);
    }
  }

  void _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialCompleted', true);
  }

  void _nextTutorialStep() {
    if (_tutorialStep < tutorialSteps.length - 1) {
      setState(() => _tutorialStep++);
    } else {
      _completeTutorial();
      setState(() {
        _tutorialStep = 0;
        _showTutorial = false;
      });
    }
  }

  static Widget _tutorialStepWidget(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class TutorialStep {
  final Widget widget;
  final GlobalKey targetKey;
  final TooltipDirection direction;
  final String description; // Add this line

  TutorialStep({
    required this.widget,
    required this.targetKey,
    required this.direction,
    required this.description, // Add this line
  });
}

enum TooltipDirection { top, right, bottom, left }

class TutorialManager {
  List<TutorialStep> tutorialSteps = [];
  int currentStep = 0;
  bool isTutorialActive = true;

  TutorialManager({
    required List<String> translatedTexts,
    required List<GlobalKey> keys,
  }) {
    initializeTutorialSteps(translatedTexts, keys);
  }

  void initializeTutorialSteps(
      List<String> translatedTexts, List<GlobalKey> keys) {
// Ensure that the translatedTexts and keys are valid before

    tutorialSteps = [
      TutorialStep(
        widget: _tutorialStepWidget(translatedTexts[9]),
        targetKey: keys[0],
        direction: TooltipDirection.right,
        description: translatedTexts[9],
      ),
      TutorialStep(
        widget: _tutorialStepWidget(translatedTexts[6]),
        targetKey: keys[1],
        direction: TooltipDirection.top,
        description: translatedTexts[5],
      ),
      TutorialStep(
        widget: _tutorialStepWidget(translatedTexts[6]),
        targetKey: keys[2],
        direction: TooltipDirection.top,
        description: translatedTexts[5],
      ),
// Add more steps as needed...
    ];
  }

  void nextTutorialStep() {
    if (currentStep < tutorialSteps.length - 1) {
      currentStep++;
    } else {
      isTutorialActive = false;
      currentStep = 0;
    }
  }

  Widget buildTutorialOverlay() {
    if (!isTutorialActive || currentStep >= tutorialSteps.length) {
      return const SizedBox.shrink();
    }

    final currentStepData = tutorialSteps[currentStep];
    final keyContext = currentStepData.targetKey.currentContext;

    if (keyContext != null) {
      final RenderBox renderBox = keyContext.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onTap: () => nextTutorialStep(),
          child: currentStepData.widget,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  static Widget _tutorialStepWidget(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black), // Added border for clarity
      ),
      child: Text(
        text.isNotEmpty ? text : "No description provided",
        style: const TextStyle(color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}
