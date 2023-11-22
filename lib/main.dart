import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:confetti/confetti.dart'; // Import the confetti package

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
  bool _showPartyAnimation = true; // State for party animation

  int _tutorialStep = 0; // To keep track of tutorial steps
  late ConfettiController _confettiController; // ConfettiController

  // Define tutorialSteps as a class-level variable using TutorialStep
  final List<TutorialStep> tutorialSteps = [
    TutorialStep(
      widget: _tutorialStepWidget('This is the Go button. Tap here to start.'),
      alignment: Alignment.bottomCenter,
    ),
    TutorialStep(
      widget: _tutorialStepWidget('Here you can enter numbers.'),
      alignment: Alignment.center,
    ),
    // Add more steps as needed
  ];

  @override
  void initState() {
    super.initState();
    _initBannerAd();

    _confettiController = ConfettiController(
        duration:
            const Duration(seconds: 10)); // Initialize the ConfettiController
    _confettiController.play();

    // Optional: Set a delay to automatically turn off the party animation
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _showPartyAnimation = false;
      });
    });
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
            //width: screenSize.width,
            //height: screenSize.height,
          ),
          // Confetti animation widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
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
                      SizedBox(
                        width: screenSize.width * 0.8,
                        child: Column(
                          children: [
                            Container(
                              width: screenSize.width * 0.8,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: TextField(
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.1),
                      Container(
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
    return Visibility(
      visible: _showTutorial,
      child: GestureDetector(
        onTap: _nextTutorialStep,
        child: Stack(
          children: [
            // Semi-transparent overlay removed to allow interaction with the page
            Align(
              alignment: tutorialSteps[_tutorialStep].alignment,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child:
                    _animatedTutorialStep(tutorialSteps[_tutorialStep].widget),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedTutorialStep(Widget widget) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: AnimationController(
                vsync: this, duration: const Duration(milliseconds: 500)),
            curve: Curves.elasticOut),
      ),
      child: Container(
        key: ValueKey<int>(_tutorialStep),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)
          ],
        ),
        child: widget,
      ),
    );
  }

  void _nextTutorialStep() {
    if (_tutorialStep < tutorialSteps.length - 1) {
      setState(() => _tutorialStep++);
    } else {
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
  final Alignment alignment;

  TutorialStep({required this.widget, required this.alignment});
}
