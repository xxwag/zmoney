import 'package:flutter/material.dart';

class TextCycleWidget extends StatefulWidget {
  const TextCycleWidget({super.key});

  @override
  TextCycleWidgetState createState() => TextCycleWidgetState();
}

class TextCycleWidgetState extends State<TextCycleWidget> {
  final List<String> translatedtexts2 = [
    "How Much?",
    "How Much?",
    "How Much?",
    "How Much?",
    "How Much?",
    "How Much?",
    "How Much?",
    "How Much?",
    "How Much?",
    "How Much?",
    "This is a game",
    "It should test your logic",
    "Enter numbers",
    "Try to enter numbers",
    "Guess a number",
    "For the Win",
    "Challenge Accepted",
    "Unveil the Secret",
    "Dare to Dream",
    "Beyond the Horizon",
    "Unlock the Mystery",
    "Explore the Unknown",
    "Embrace the Adventure",
    "Solve the Puzzle",
    "Discover the Magic",
    "Journey Awaits",
    "The Final Countdown",
    "Race Against Time",
    "Capture the Moment",
    "Seize the Day",
    "A Leap of Faith",
    "Break the Silence",
    "Reach for the Stars",
    "Ignite the Flame",
    "Chase the Sunset",
    "Beyond Dreams",
    "Whispers of the Old World",
    "Echoes of the Future",
    "Dance with Destiny",
    "Sing the Blues Away",
    "Ride the Winds of Change",
    "A Twist of Fate",
    "Unravel the Mystery",
    "Defy the Odds",
    "Across the Universe",
    "Beneath the Surface",
    "Against All Odds",
    "Among the Stars",
    "Navigate the Storm",
    "Light Up the Dark",
    "Colors of the Wind",
  ];

  int _currentIndex = 0;

  void _updateText() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % translatedtexts2.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _updateText,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          translatedtexts2[_currentIndex], // Use translated text
          key: ValueKey<int>(_currentIndex),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
