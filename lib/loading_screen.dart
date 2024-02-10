import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_api_availability/google_api_availability.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  GooglePlayServicesAvailability _playStoreAvailability =
      GooglePlayServicesAvailability.unknown;
  String _errorString = 'unknown';
  bool _isUserResolvable = false;
  bool _errorDialogFragmentShown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Duration of the fade animation
      vsync: this,
    );
    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    // Check Google Play services availability when the screen is loaded
    checkGooglePlayServices();
  }

  // Function to check Google Play services availability
  Future<void> checkGooglePlayServices() async {
    GooglePlayServicesAvailability availability;

    try {
      availability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability(
              false); // Set to true to show a fix dialog if available
    } on PlatformException {
      availability = GooglePlayServicesAvailability.unknown;
    }

    setState(() {
      _playStoreAvailability = availability;
    });

    if (availability == GooglePlayServicesAvailability.success) {
      // Continue loading the screen or perform any other actions
      _controller.forward();
    } else {
      // Handle other cases (e.g., unavailable or unknown)
      // You can choose to show an error message or take appropriate action
      _errorString = 'Google Play Services: Not Available';
      _isUserResolvable = false;
    }
  }

  // Function to show error dialog fragment
  Future<void> showErrorDialogFragment() async {
    bool errorDialogFragmentShown;

    try {
      errorDialogFragmentShown =
          await GoogleApiAvailability.instance.showErrorDialogFragment();
    } on PlatformException {
      errorDialogFragmentShown = false;
    }

    setState(() {
      _errorDialogFragmentShown = errorDialogFragmentShown;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: _opacityAnimation.value,
            child: Image.asset(
              'assets/mainscreen.png', // Replace with your image asset or network image
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          // Other widgets like text can go here

          // Display Google Play Services information and options
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Google Play Services Availability:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _playStoreAvailability.toString().split('.').last,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Error String:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _errorString,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Error Resolvable by User:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isUserResolvable ? 'Yes' : 'No',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => showErrorDialogFragment(),
                  child: Text('Show Error Dialog Fragment'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
