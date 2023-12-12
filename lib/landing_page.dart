import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math; // Import the math library
import 'package:http/http.dart' as http;

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zmoney/ngrok.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingTime = 600;
  late bool _timerStarted = false;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  bool _showTutorial = true; // State to manage tutorial visibility
  final bool _showPartyAnimation = true; // State for party animation
  final TextEditingController _numberController = TextEditingController();

  bool _isWaitingForResponse = false;

  int _tutorialStep = 0; // To keep track of tutorial steps
  late ConfettiController _confettiController; // ConfettiController

  // GlobalKeys for target widgets
  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  // Add more keys as needed

  String _selectedLanguageCode = 'en'; // Default language code

  String translatedText1 = 'How Much?';
  String translatedText2 = 'Enter Numbers';
  String translatedText3 = 'Go!';
  String translatedText4 = 'Ready';
  String translatedText5 = 'The next try will be available in:';
  String translatedText6 = 'This is the Go button. Tap here to start.';
  String translatedText7 = 'Tap the Go button to start your journey!';
  String translatedText8 = 'Here you can enter numbers.';
  String translatedText9 = 'Enter numbers in this field.';
  String translatedText10 = '';
  List<TutorialStep> tutorialSteps = [];

  void _incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    int launchCount = prefs.getInt('launchCount') ?? 0;
    prefs.setInt('launchCount', launchCount + 1);
  }

  //INIT STATE <<<<<<<<<<<<<<<<<<<<
  @override
  void initState() {
    super.initState();

    NgrokManager.fetchNgrokData();
    fetchAndSetTranslations(_selectedLanguageCode);
    _incrementLaunchCount();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();

    // TADY SE MUSI DODELAT TUTORIAL STEPY, KAZDEJ JE NAVAZANEJ NA KEY (key1, key2) KTERYM SE MUSI OZNACIT ELEMENT WIDGETU
    // VIz. DOLE TUTORIAL STEP CLASS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 0), () {
        // Adjust the duration as needed
        if (mounted) {
          setState(() {
            _showTutorial = true;
            tutorialSteps = [
              TutorialStep(
                widget: _tutorialStepWidget(translatedText6),
                targetKey: key1,
                direction: TooltipDirection.bottom,
                description: translatedText7, // Add description
              ),
              TutorialStep(
                widget: _tutorialStepWidget(translatedText8),
                targetKey: key2,
                direction: TooltipDirection.top,
                description: translatedText9, // Add description
              ),
              // Additional steps...
            ];
          });
        }
      });
    });

    // Check if the tutorial has been completed previously
    _checkTutorialCompletion();
    _initBannerAd();
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

  Future<String> combineTextsForTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    const separator = "|||"; // Unique separator
    List<String> texts = [];

    // Fetch each translation from shared preferences
    for (int i = 1; i <= 10; i++) {
      String key = 'translatedText$i$_selectedLanguageCode';
      String text = prefs.getString(key) ?? "Default Text $i";
      texts.add(text);
    }

    return texts.join(separator);
  }

  Future<String> translateText(String text, String toLang,
      {String fromLang = 'en'}) async {
    var url = Uri.parse(
        'https://libretranslate.de/translate'); // LibreTranslate API URL

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "q": text,
          "source": fromLang,
          "target": toLang,
          "format": "text"
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['translatedText'];
      } else {
        print('Failed to translate. Status code: ${response.statusCode}');
        return text; // Return original text on failure
      }
    } catch (e) {
      print('Error occurred: $e');
      return text; // Return original text on error
    }
  }

//GARBAGE BELLOW TO BE SEEN, IM 2LAZY TO CHANGE THE INITIAL SET OF STRINGS INT LIST AND CALL IT EVERYTIME FROM THE WIDGETS FROM IT🤷
  Future<void> fetchAndSetTranslations(String targetLanguageCode) async {
    final prefs = await SharedPreferences.getInstance();
    print("Fetching translations for language code: $targetLanguageCode");

    // Attempt to retrieve previously stored translations
    String? storedTranslatedText1 =
        prefs.getString('translatedText1_$targetLanguageCode');
    String? storedTranslatedText2 =
        prefs.getString('translatedText2_$targetLanguageCode');
    String? storedTranslatedText3 =
        prefs.getString('translatedText3_$targetLanguageCode');
    String? storedTranslatedText4 =
        prefs.getString('translatedText4_$targetLanguageCode');
    String? storedTranslatedText5 =
        prefs.getString('translatedText5_$targetLanguageCode');
    String? storedTranslatedText6 =
        prefs.getString('translatedText6_$targetLanguageCode');
    String? storedTranslatedText7 =
        prefs.getString('translatedText7_$targetLanguageCode');
    String? storedTranslatedText8 =
        prefs.getString('translatedText8_$targetLanguageCode');
    String? storedTranslatedText9 =
        prefs.getString('translatedText9_$targetLanguageCode');
    String? storedTranslatedText10 =
        prefs.getString('translatedText10_$targetLanguageCode');

    // Check if all translations are available in shared preferences
    bool areTranslationsAvailable = storedTranslatedText1 != null &&
        storedTranslatedText2 != null &&
        storedTranslatedText3 != null &&
        storedTranslatedText4 != null &&
        storedTranslatedText5 != null &&
        storedTranslatedText6 != null &&
        storedTranslatedText7 != null &&
        storedTranslatedText8 != null &&
        storedTranslatedText9 != null &&
        storedTranslatedText10 != null;

    if (!areTranslationsAvailable) {
      print(
          "Translations not available in shared preferences. Proceeding with translation.");

      // Use 'await' to properly get the result from the async function
      String combinedTexts = await combineTextsForTranslation();
      print("Combined texts for translation: $combinedTexts");

      String translatedCombinedTexts =
          await translateText(combinedTexts, targetLanguageCode);
      print("Received translated text: $translatedCombinedTexts");
      List<String> individualTranslations =
          translatedCombinedTexts.split("|||");

      // Ensure there are enough elements in the list
      if (individualTranslations.length < 10) {
        print(
            "Warning: Received fewer translations than expected. Filling missing translations.");
      }
      while (individualTranslations.length < 10) {
        individualTranslations.add("Translation Missing");
      }
      print(
          "Warning: Received fewer translations than expected. Filling missing translations.");

      // Update state and store new translations
      setState(() {
        translatedText1 = individualTranslations[0].trim();
        prefs.setString('translatedText1_$targetLanguageCode', translatedText1);
        print(
            "Stored 'translatedText1' for '$targetLanguageCode': $translatedText1");

        translatedText2 = individualTranslations[1].trim();
        prefs.setString('translatedText2_$targetLanguageCode', translatedText2);
        print(
            "Stored 'translatedText2' for '$targetLanguageCode': $translatedText2");

        translatedText3 = individualTranslations[2].trim();
        prefs.setString('translatedText3_$targetLanguageCode', translatedText3);
        print(
            "Stored 'translatedText3' for '$targetLanguageCode': $translatedText3");

        translatedText4 = individualTranslations[3].trim();
        prefs.setString('translatedText4_$targetLanguageCode', translatedText4);
        print(
            "Stored 'translatedText4' for '$targetLanguageCode': $translatedText4");

        translatedText5 = individualTranslations[4].trim();
        prefs.setString('translatedText5_$targetLanguageCode', translatedText5);
        print(
            "Stored 'translatedText5' for '$targetLanguageCode': $translatedText5");

        translatedText6 = individualTranslations[5].trim();
        prefs.setString('translatedText6_$targetLanguageCode', translatedText6);
        print(
            "Stored 'translatedText6' for '$targetLanguageCode': $translatedText6");

        translatedText7 = individualTranslations[6].trim();
        prefs.setString('translatedText7_$targetLanguageCode', translatedText7);
        print(
            "Stored 'translatedText7' for '$targetLanguageCode': $translatedText7");

        translatedText8 = individualTranslations[7].trim();
        prefs.setString('translatedText8_$targetLanguageCode', translatedText8);
        print(
            "Stored 'translatedText8' for '$targetLanguageCode': $translatedText8");

        translatedText9 = individualTranslations[8].trim();
        prefs.setString('translatedText9_$targetLanguageCode', translatedText9);
        print(
            "Stored 'translatedText9' for '$targetLanguageCode': $translatedText9");

        translatedText10 = individualTranslations[9].trim();
        prefs.setString(
            'translatedText10_$targetLanguageCode', translatedText10);
        print(
            "Stored 'translatedText10' for '$targetLanguageCode': $translatedText10");

        print(
            "All translations updated and stored in shared preferences for '$targetLanguageCode'.");
        print("Translations updated and stored in shared preferences.");
      });
    } else {
      print("Using stored translations from shared preferences.");
      setState(() {
        translatedText1 = storedTranslatedText1;
        translatedText2 = storedTranslatedText2;
        translatedText3 = storedTranslatedText3;
        translatedText4 = storedTranslatedText4;
        translatedText5 = storedTranslatedText5;
        translatedText6 = storedTranslatedText6;
        translatedText7 = storedTranslatedText7;
        translatedText8 = storedTranslatedText8;
        translatedText9 = storedTranslatedText9;
        translatedText10 = storedTranslatedText10;
        print("Using stored translations from shared preferences.");
      });
    }
  }

  Widget _buildLanguageSelector() {
    Map<String, String> languages = {
      'en': 'English',
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

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-4652990815059289/6968524603', // Test ad unit ID
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

  @override
  void dispose() {
    _timer?.cancel();
    _bannerAd.dispose();
    _confettiController.dispose();
    super.dispose();
  }

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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    // Calculate maxBlastForce based on screen width, with a maximum limit
    double calculatedBlastForce = screenSize.width / 1; // Example calculation
    double maxAllowedBlastForce = 2000; // Set your maximum limit here
    double maxBlastForce = math.min(calculatedBlastForce, maxAllowedBlastForce);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            color: _showPartyAnimation
                ? Colors.yellow
                : const Color(0xFF369A82), // Switch background color
          ),
          // TADY MAME HAFO PROBLEMU, CHTELO BY TO CUSTOM ANIMATION CONTROLLER
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.directional,
              blastDirection: -math.pi / 1, // For straight-down particles
              particleDrag: 0.05, // Drag of the particles
              minBlastForce: 1, // Minimum blast force
              maxBlastForce:
                  maxBlastForce, // Dynamically calculated with a limit
              emissionFrequency: 0.05, // Frequency of emission (within 0 to 1)
              numberOfParticles: 13, // Number of particles
              gravity: 0.01, // Gravity effect on particles
              colors: const [Colors.green], // Color of particles
            ),
          ),
          // Main content in a Column
          Positioned(
            top: 20,
            left: 20,
            child:
                _buildLanguageSelector(), // Language selector at the top left corner
          ),
          Column(
            children: [
              if (_isBannerAdReady)
                SizedBox(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        translatedText1, // Use translated text
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0D251F),
                          fontSize: 40,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.1),
                      _buildNumberInput(screenSize, translatedText2),
                      SizedBox(height: screenSize.height * 0.1),
                      _buildGoButton(screenSize, translatedText3),
                      SizedBox(height: screenSize.height * 0.1),
                      GestureDetector(
                        onTap: startTimer,
                        child: Text(
                          _timerStarted
                              ? '$translatedText5 ${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
                              : translatedText4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _showTutorial ? _buildTutorialOverlay() : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> submitGuess() async {
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

        return WillPopScope(
          onWillPop: () async => false, // Disable closing by back button
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
        return WillPopScope(
          onWillPop: () async => false, // Disable closing by back button
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

  Widget _buildTutorialOverlay() {
    if (_tutorialStep >= tutorialSteps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = tutorialSteps[_tutorialStep];
    final keyContext = currentStep.targetKey.currentContext;

    if (keyContext != null) {
      final RenderBox renderBox = keyContext.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onTap: _nextTutorialStep,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tutorial Step $_tutorialStep',
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  currentStep.description, // Display the description
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
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

  Widget _buildGoButton(Size screenSize, String buttonText) {
    return GestureDetector(
      onTap: () {
        if (!_isWaitingForResponse && !_timerStarted) {
          submitGuess();
        }
      },
      child: Container(
        key: key2, // Assign the GlobalKey here
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
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
