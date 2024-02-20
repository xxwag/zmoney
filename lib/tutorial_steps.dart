import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TooltipDirection { top, right, bottom, left }

class TutorialStep {
  final Widget widget;
  final GlobalKey targetKey;
  final TooltipDirection direction;
  final String description;
  final Function onTap; // Added callback for tap action

  TutorialStep({
    required this.widget,
    required this.targetKey,
    required this.direction,
    required this.description,
    required this.onTap, // Require the callback in the constructor
  });
}

class TutorialManager {
  List<TutorialStep> tutorialSteps = [];
  int currentStep = 0;
  bool isTutorialActive = true;
  bool showTutorial = false; // Default to showing the tutorial.

  TutorialManager({
    required List<String> translatedTexts,
    required List<GlobalKey> keys,
  }) {
    loadPreferences().then((_) {
      // Ensure tutorial steps are initialized after preferences are loaded.

      if (!showTutorial) {
        initializeTutorialSteps(translatedTexts, keys);
      } else {}
    });
  }

  Future<void> loadPreferences() async {
    // Load the preference.
  }

  void initializeTutorialSteps(
      List<String> translatedTexts, List<GlobalKey> keys) {
// Ensure that the translatedTexts and keys are valid before

    tutorialSteps = [
      TutorialStep(
        widget: TutorialStepWidget(
            description: translatedTexts[9], onTap: nextTutorialStep),
        targetKey: keys[0],
        direction: TooltipDirection.bottom,
        description: translatedTexts[9],
        onTap: nextTutorialStep,
      ),
      TutorialStep(
        widget: TutorialStepWidget(
            description: translatedTexts[8], onTap: nextTutorialStep),
        targetKey: keys[1],
        direction: TooltipDirection.top,
        description: translatedTexts[8],
        onTap: nextTutorialStep,
      ),
      TutorialStep(
        widget: TutorialStepWidget(
            description: translatedTexts[4], onTap: nextTutorialStep),
        targetKey: keys[2],
        direction: TooltipDirection.top,
        description: translatedTexts[4],
        onTap: nextTutorialStep,
      ),
      TutorialStep(
        widget: TutorialStepWidget(
            description: translatedTexts[6], onTap: nextTutorialStep),
        targetKey: keys[3],
        direction: TooltipDirection.top,
        description: translatedTexts[6],
        onTap: nextTutorialStep,
      ),
// Add more steps as needed...
    ];
  }

  void nextTutorialStep() async {
    if (currentStep < tutorialSteps.length - 1) {
      currentStep++;
    } else {
      isTutorialActive = false;
      currentStep = 0;
      // Tutorial completed, store the attribute in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorialCompleted', true);

      final tutorialCompleted = prefs.getBool('tutorialCompleted') ?? false;
      if (kDebugMode) {
        print('wtf2$tutorialCompleted');
      }
    }
  }

  Widget buildTutorialOverlay(BuildContext context) {
    if (!isTutorialActive || currentStep >= tutorialSteps.length) {
      return const SizedBox.shrink();
    }

    final currentStepData = tutorialSteps[currentStep];
    final keyContext = currentStepData.targetKey.currentContext;

    if (keyContext != null) {
      final RenderBox renderBox = keyContext.findRenderObject() as RenderBox;
      final targetPosition = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;

      // Size of the tutorial step widget, adjust as needed
      const tutorialWidgetSize = Size(300, 100); // Example size

      // Calculate position for the tutorial widget
      double left = targetPosition.dx;
      double top = targetPosition.dy;

      // Adjust for screen edges
      if (left + tutorialWidgetSize.width > screenSize.width) {
        left = screenSize.width - tutorialWidgetSize.width;
      }
      if (top + tutorialWidgetSize.height > screenSize.height) {
        top = screenSize.height - tutorialWidgetSize.height;
      }

      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onTap: () => nextTutorialStep(),
          child: SizedBox(
            width: tutorialWidgetSize.width,
            height: tutorialWidgetSize.height,
            child: currentStepData.widget,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class TutorialStepWidget extends StatefulWidget {
  final String description;
  final Function onTap; // Callback for tap action

  const TutorialStepWidget(
      {super.key, required this.description, required this.onTap});

  @override
  _TutorialStepWidgetState createState() => _TutorialStepWidgetState();
}

class _TutorialStepWidgetState extends State<TutorialStepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation =
        Tween<double>(begin: 0.5, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            widget.onTap(); // Call the provided onTap callback.
            _animationController.forward(
                from: 0.0); // Restart the animation from the beginning.
          },
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 25), // Adjusted padding
              margin: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.transparent),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.transparent,
                    offset: Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Use minimum space needed by the column's children
                children: [
                  Flexible(
                    child: Text(
                      widget.description.isNotEmpty
                          ? widget.description
                          : "No description provided",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                        fontFamily: 'Proxima',
                        height: 1.2, // Adjusted line height
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true, // Ensure text wraps
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
