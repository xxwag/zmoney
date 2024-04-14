import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class SmileyFaceThrower {
  static final List<String> smileyTexts = [
    '😀',
    '😁',
    '😂',
    '🤣',
    '😃',
    '😄',
    '😅',
    '😆',
    '😉',
    '😊',
  ];

  static final List<String> fontFamilies = [
    'CartoonFont1',
    'CartoonFont2',
    'CartoonFont3',
    'CartoonFont4',
    'CartoonFont5',
    'CartoonFont6',
  ];

  static final List<String> descriptionTexts = [
    'Always smiling!',
    'Keep happy!',
    'Laughter is the best medicine!',
    'Cheer up!',
    'Let’s spread some joy!',
    // Add more descriptions as desired
  ];
  static void showSmiley(BuildContext context) {
    final random = Random();
    final smileyText = smileyTexts[random.nextInt(smileyTexts.length)];
    final selectedFont = fontFamilies[random.nextInt(fontFamilies.length)];
    final descriptionText =
        descriptionTexts[random.nextInt(descriptionTexts.length)];

    final removeOverlay = _RemoveOverlay();

    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final startPosition = Offset(
          random.nextBool()
              ? -100
              : size.width + 100, // Start outside screen horizontally
          random.nextDouble() * size.height, // Random vertical start
        );
        final endPosition = Offset(
          size.width / 2, // Center of the screen horizontally
          size.height / 2, // Center of the screen vertically
        );

        return AnimatedSmiley(
          startPosition: startPosition,
          endPosition: endPosition,
          smileyText: smileyText,
          selectedFont: selectedFont,
          descriptionText: descriptionText,
          onEnd: () => removeOverlay.call(),
          duration: Duration(
              seconds:
                  random.nextInt(3) + 5), // Randomize between 5 to 7 seconds
        );
      },
    );

    removeOverlay.overlayEntry = overlayEntry;
    Overlay.of(context).insert(overlayEntry);
  }
}

class _RemoveOverlay {
  late OverlayEntry overlayEntry;

  void call() {
    overlayEntry.remove();
  }
}

class AnimatedSmiley extends StatefulWidget {
  final Offset startPosition;
  final Offset endPosition;
  final String smileyText;
  final String selectedFont;
  final String descriptionText; // New parameter for description text
  final VoidCallback onEnd;
  final Duration duration;

  const AnimatedSmiley({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.smileyText,
    required this.selectedFont,
    required this.descriptionText, // Initialize the descriptionText
    required this.onEnd,
    required this.duration, // Accept duration
  });

  @override
  AnimatedSmileyState createState() => AnimatedSmileyState();
}

class AnimatedSmileyState extends State<AnimatedSmiley>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeAnimation;
  late final Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..forward();
    _sizeAnimation =
        Tween<double>(begin: 50.0, end: 100.0).animate(_controller);
    _positionAnimation =
        Tween<Offset>(begin: widget.startPosition, end: widget.endPosition)
            .animate(_controller)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onEnd();
            }
          });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _sizeAnimation.value / 50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.smileyText,
                        style: TextStyle(
                          decoration: TextDecoration.none,

                          fontSize: _sizeAnimation.value,
                          // Not applying the selected font to the emoji
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 4.0), // Padding between the icon and description
                  child: AutoSizeText(
                    minFontSize: 18,
                    maxFontSize: 23,
                    widget
                        .descriptionText, // Use the randomly selected description text
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      backgroundColor: Colors.transparent,
                      fontSize: 20, // Adjust based on your preference
                      fontFamily: widget
                          .selectedFont, // Apply the selected font only to the description
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
