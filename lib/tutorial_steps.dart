import 'package:flutter/material.dart';

enum TooltipDirection { top, right, bottom, left }

class TutorialStep {
  final Widget widget;
  final GlobalKey targetKey;
  final TooltipDirection direction;
  final String description;

  TutorialStep({
    required this.widget,
    required this.targetKey,
    required this.direction,
    required this.description,
  });
}

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
        widget: _tutorialStepWidget(translatedTexts[7]),
        targetKey: keys[0],
        direction: TooltipDirection.bottom,
        description: translatedTexts[7],
      ),
      TutorialStep(
        widget: _tutorialStepWidget(translatedTexts[6]),
        targetKey: keys[1],
        direction: TooltipDirection.top,
        description: translatedTexts[6],
      ),
      TutorialStep(
        widget: _tutorialStepWidget(translatedTexts[5]),
        targetKey: keys[2],
        direction: TooltipDirection.top,
        description: translatedTexts[5],
      ),
      TutorialStep(
        widget: _tutorialStepWidget(translatedTexts[4]),
        targetKey: keys[3],
        direction: TooltipDirection.top,
        description: translatedTexts[4],
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

  Widget buildTutorialOverlay(BuildContext context) {
    if (!isTutorialActive || currentStep >= tutorialSteps.length) {
      return const SizedBox.shrink();
    }

    final currentStepData = tutorialSteps[currentStep];
    final keyContext = currentStepData.targetKey.currentContext;

    if (keyContext != null) {
      final RenderBox renderBox = keyContext.findRenderObject() as RenderBox;
      final targetPosition = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;
      final screenSize = MediaQuery.of(context).size;

      // Size of the tutorial step widget, adjust as needed
      final tutorialWidgetSize = Size(300, 100); // Example size

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
          child: Container(
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
