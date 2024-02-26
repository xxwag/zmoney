import 'dart:async';

import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _showLoadingTips = false;
  Timer? _loadingTimer;
  final List<String> _visibleReasons = [];
  final List<double> _opacityLevels = []; // Track opacity for each reason

  final List<String> _loadingReasons = [
    "Something is not adding up🤔",
    "Maybe the connection is slow?",
    "Or turned off ..🤭",
    "Check those while waiting here ❤️",
    "We are loading up to no data 💔",
    "Yes still waiting for the server to respond...",
    "Stil waiting ...",
    "Cannot connect to the authorization server",
    "Try restarting the app if nothing helps.",
    // Add more reasons here
  ];

  @override
  void initState() {
    super.initState();

    // Start the timer to show tips after 10 seconds
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _showLoadingTips = true;
      });
      _showReasonsOneByOne();
    });
  }

  void _showReasonsOneByOne() {
    for (int i = 0; i < _loadingReasons.length; i++) {
      Timer(Duration(seconds: 2 * i), () {
        if (i < _loadingReasons.length) {
          setState(() {
            _visibleReasons.add(_loadingReasons[i]);
            _opacityLevels.add(0); // Initialize opacity to 0
          });
          _fadeInReason(i);
        }
      });
    }
  }

  void _fadeInReason(int index) {
    Timer(const Duration(milliseconds: 100), () {
      // Ensure opacity does not exceed 1.0
      if (_opacityLevels[index] < 1) {
        double newOpacity = _opacityLevels[index] + 0.1; // Increase opacity
        setState(() {
          _opacityLevels[index] =
              newOpacity > 1.0 ? 1.0 : newOpacity; // Clamp opacity to max 1.0
        });
        if (_opacityLevels[index] < 1) {
          _fadeInReason(index); // Continue fading in only if opacity < 1
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/mainscreen.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child:
              _showLoadingTips ? _buildLoadingTips() : _buildLoadingIndicator(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }

  Widget _buildLoadingTips() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _visibleReasons.asMap().entries.map((entry) {
        int idx = entry.key;
        String reason = entry.value;
        int totalCount = _visibleReasons.length;

        // Ensure opacity is within valid range
        double opacity = _opacityLevels[idx].clamp(0.0, 1.0);

        return AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(
              milliseconds: 500), // Control the speed of the fade in
          child: Container(
            margin: const EdgeInsets.only(
                bottom: 8), // Add some spacing between items
            decoration: BoxDecoration(
              color: Colors.black45, // Semi-transparent background
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            child: ListTile(
              title: FittedBox(
                fit: BoxFit.scaleDown, // Shrink the text to fit on one line
                child: Text(
                  reason,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              leading: (idx == 0 || idx == totalCount - 1)
                  ? const Icon(Icons.info_outline, color: Colors.white)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }
}
