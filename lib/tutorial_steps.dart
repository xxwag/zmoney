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

    if (translatedTexts.length>= 2){ //&& keys.length >= 2) {
      tutorialSteps = [
        TutorialStep(
          widget: _tutorialStepWidget(translatedTexts[7]),
          targetKey: keys[0],
          direction: TooltipDirection.bottom,
          description: translatedTexts[8],
        ),
        TutorialStep(
          widget: _tutorialStepWidget(translatedTexts[6]),
          targetKey: keys[1],
          direction: TooltipDirection.bottom,
          description: translatedTexts[5],
        ),
// Add more steps as needed...
      ];
    }
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
