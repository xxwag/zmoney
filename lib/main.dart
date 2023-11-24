import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:confetti/confetti.dart'; // Import the confetti package
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math; // Import the math library

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

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

  int _tutorialStep = 0; // To keep track of tutorial steps
  late ConfettiController _confettiController; // ConfettiController

  // GlobalKeys for target widgets
  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  // Add more keys as needed

  late List<TutorialStep> tutorialSteps;

  void _incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    int launchCount = prefs.getInt('launchCount') ?? 0;
    prefs.setInt('launchCount', launchCount + 1);
  }

  @override
  void initState() {
    super.initState();

    _incrementLaunchCount();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        // Adjust the duration as needed
        if (mounted) {
          setState(() {
            _showTutorial = true;
            tutorialSteps = [
              TutorialStep(
                widget: _tutorialStepWidget(
                    'This is the Go button. Tap here to start.'),
                targetKey: key1,
                direction: TooltipDirection.bottom,
                description:
                    'Tap the Go button to start your journey!', // Add description
              ),
              TutorialStep(
                widget: _tutorialStepWidget('Here you can enter numbers.'),
                targetKey: key2,
                direction: TooltipDirection.top,
                description: 'Enter numbers in this field.', // Add description
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

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            color: _showPartyAnimation
                ? Colors.yellow
                : const Color(0xFF369A82), // Switch background color
          ),
          // Confetti animation widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.directional,
              blastDirection:
                  -math.pi / 2, // Makes particles fall straight down
              particleDrag: 0.05, // Apply drag to the particles
              emissionFrequency: 0.05, // Control emission frequency
              numberOfParticles: 20, // Number of particles to be emitted
              gravity: 0.05, // Adjust gravity to make it look like raining
              colors: const [
                Colors.green
              ], // Colors can be adjusted or made transparent for images
              // Other properties as per your design
            ),
          ),
          // Main content in a Column
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
                      const Text(
                        'How much?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF0D251F),
                          fontSize: 40,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.1),
                      _buildNumberInput(screenSize),
                      SizedBox(height: screenSize.height * 0.1),
                      _buildGoButton(screenSize),
                      SizedBox(height: screenSize.height * 0.1),
                      GestureDetector(
                        onTap: startTimer,
                        child: Text(
                          _timerStarted
                              ? 'Next try will be available in ${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
                              : 'Ready',
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
          _showTutorial
              ? _buildTutorialOverlay()
              : const SizedBox.shrink(), // Tutorial overlay
        ],
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

  Widget _buildNumberInput(Size screenSize) {
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
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter numbers',
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

  Widget _buildGoButton(Size screenSize) {
    return Container(
      key: key2, // Assign the GlobalKey here
      child: GestureDetector(
        onTap: () {
          startTimer();
          _playConfettiAnimation(); // Play confetti on interaction
        },
        child: Container(
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
          child: const Text(
            'Go!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
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
