import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:zmoney/main.dart';
import 'package:zmoney/ngrok.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SideMenuDrawer extends StatefulWidget {
  final List<String> translatedTexts;
  final Color containerColor; // Assuming this is the color you want to pass

  const SideMenuDrawer({
    super.key,
    required this.translatedTexts,
    required this.containerColor,
  });

  @override
  SideMenuDrawerState createState() => SideMenuDrawerState();
}

class SideMenuDrawerState extends State<SideMenuDrawer> {
  late Color containerColor; // Late declaration

  @override
  void initState() {
    super.initState();
    containerColor = widget.containerColor; // Initialization
    // Access the singleton VideoPlayerManager instance
    VideoPlayerManager().play();
  }

  void showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.translatedTexts[10]), // Title text for the dialog
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(widget.translatedTexts[11]), // Game Rule 1
                Text(widget.translatedTexts[12]), // Game Rule 2
                // Add more rules as needed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the shared video player controller
    final videoPlayerController = VideoPlayerManager().videoPlayerController;

    // Check if the video player controller is initialized
    final isControllerInitialized = videoPlayerController != null &&
        videoPlayerController.value.isInitialized;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          SizedBox(
            height: 200.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Use the VideoPlayerManager's controller if initialized
                if (isControllerInitialized)
                  VideoPlayer(videoPlayerController!)
                else
                  Container(
                    color: containerColor,
                    child: Center(
                        child:
                            CircularProgressIndicator()), // Show loading spinner
                  ),
                // Overlay content
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.translatedTexts[10],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text(
                'Rules'), // You might want to use one of the translated texts here
            onTap: () => showRulesDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(widget.translatedTexts[14]), // 'Settings' text
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.balance),
            title: Text(widget
                .translatedTexts[5]), // Assuming this is the balance list title
            onTap: () {
              // Navigate to MoneyWithdrawalScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MoneyWithdrawalScreen()), // Use the actual constructor of your MoneyWithdrawalScreen
              );
            },
          ),
          // Additional ListTiles for other drawer items...
        ],
      ),
    );
  }

  @override
  void dispose() {
    //_videoPlayerController.dispose();
    super.dispose();
  }
}

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  VideoPlayerController? videoPlayerController;

  factory VideoPlayerManager() {
    return _instance;
  }

  VideoPlayerManager._internal() {
    // Initialize your video player here
    videoPlayerController = VideoPlayerController.asset('assets/videos/8s.mp4')
      ..initialize().then((_) {
        videoPlayerController?.setLooping(true);
        // Optionally, start playing immediately or wait until needed
      });
  }

  void play() {
    if (!videoPlayerController!.value.isPlaying) {
      videoPlayerController?.play();
    }
  }

  void pause() {
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController?.pause();
    }
  }

  // Use dispose with caution, only when you're sure it won't be needed anymore
  void dispose() {
    videoPlayerController?.dispose();
    videoPlayerController = null;
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  Future<void> _wipePlayerData() async {
    String endpoint = '${NgrokManager.ngrokUrl}/api/zdatawipe';
    try {
      final jwtToken = await _secureStorage.read(key: 'jwtToken');
      if (kDebugMode) {
        print(jwtToken);
      }
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': jwtToken}),
      );

      if (response.statusCode == 200) {
        // Assuming the endpoint returns a success message upon wiping data
        _showMessage('Player data wiped successfully.');
      } else {
        // Handle server errors or invalid responses
        _showMessage('Failed to wipe player data. Please try again.');
      }
    } catch (e) {
      // Handle errors like no internet connection
      _showMessage('An error occurred: $e');
    }
  }

  void _signOut() async {
    // Delete JWT token from secure storage
    await _secureStorage.delete(key: 'jwtToken');

    // Access SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Clear SharedPreferences
    await prefs.clear();

    // Sign out from GoogleSignIn
    try {
      await _googleSignIn
          .signOut(); // Or use disconnect() if you want to revoke access completely
      await FirebaseAuth.instance.signOut();
      if (kDebugMode) {
        print("Signed out of Google");
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error signing out of Google: $error");
      }
    }

    // Navigate to WelcomeScreen if the context is still mounted
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()));
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Message"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Wipe Player Data'),
            onTap: _wipePlayerData,
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: _signOut,
          ),
          // Add more settings here as needed
        ],
      ),
    );
  }
}

class MoneyWithdrawalScreen extends StatefulWidget {
  @override
  _MoneyWithdrawalScreenState createState() => _MoneyWithdrawalScreenState();
}

class _MoneyWithdrawalScreenState extends State<MoneyWithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  double _totalZcoins = 0.0;
  double _realMoneyValue = 0.0;
  double _sliderValue = 0;
  static const double _conversionRate = 0.01; // 1 Zcoin = 0.01 dollars

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    String? playerDataString = prefs.getString('playerData');
    if (playerDataString != null) {
      final Map<String, dynamic> playerData = jsonDecode(playerDataString);
      setState(() {
        _totalZcoins =
            (playerData['total_win_amount'] as num?)?.toDouble() ?? 0.0;
        _realMoneyValue = _totalZcoins * _conversionRate;
        _amountController.text =
            (_realMoneyValue * _sliderValue / 100).toStringAsFixed(2);
      });
    }
  }

  void _updateAmountFromSlider(double value) {
    setState(() {
      _sliderValue = value;
      _amountController.text =
          (_realMoneyValue * value / 100).toStringAsFixed(2);
    });
  }

  void _navigateToCardForm(BuildContext context, String cardType,
      double selectedZcoins, double selectedAmountInDollars) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardPaymentForm(
          cardType: cardType,
          selectedZcoins: selectedZcoins,
          selectedAmountInDollars: selectedAmountInDollars,
        ),
      ),
    );
  }

  void _showUnfinishedMethodDialog(BuildContext context, String methodName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Method Unavailable"),
          content: Text(
              "The process for $methodName withdrawal is not ready yet. We are so sorry. Please try a different method."),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showPaymentOptions(BuildContext context) async {
    final paymentMethod = await showModalBottomSheet<String?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.account_balance_wallet),
                  title: Text('Bitcoin'),
                  onTap: () => Navigator.pop(context, 'Bitcoin')),
              ListTile(
                  leading: Icon(Icons.credit_card),
                  title: Text('Mastercard'),
                  onTap: () => Navigator.pop(context, 'Mastercard')),
              ListTile(
                  leading: Icon(Icons.credit_card),
                  title: Text('Visa'),
                  onTap: () => Navigator.pop(context, 'Visa')),
              ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('PayPal'),
                  onTap: () => Navigator.pop(context, 'PayPal')),
              ListTile(
                  leading: Icon(Icons.phone_android),
                  title: Text('Google Pay'),
                  onTap: () => Navigator.pop(context, 'Google Pay')),
            ],
          ),
        );
      },
    );

    if (paymentMethod != null) {
      if (paymentMethod == 'Mastercard' || paymentMethod == 'Visa') {
        // Calculate the selected amount in Zcoins and its equivalent in real money
        final double selectedAmountInDollars =
            double.parse(_amountController.text);
        final double selectedZcoins = selectedAmountInDollars / _conversionRate;

        // Now pass these values to _navigateToCardForm
        _navigateToCardForm(
            context, paymentMethod, selectedZcoins, selectedAmountInDollars);
      } else if (paymentMethod == 'Google Pay') {
        _initiateWithdrawal(paymentMethod, context);
      }
      // Additional conditions for other payment methods can be added here.
    }
  }

  void _initiateWithdrawal(String paymentMethod, BuildContext context) {
    // Here, you would integrate with the actual payment method's API or SDK.
    // This is a placeholder to simulate the transfer process.
    print("Initiating transfer with: $paymentMethod");

    // Simulate opening a transfer window or processing the payment.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$paymentMethod Transfer'),
        content:
            Text('Simulating a transfer request window for $paymentMethod.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessDialog(100.0); // Placeholder for successful transfer
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(double amountWithdrawn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdrawal Successful'),
        content: Text(
            'You have successfully withdrawn \$${amountWithdrawn.toStringAsFixed(2)}'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate remaining balance after withdrawal
    double remainingBalanceAfterWithdrawal =
        _realMoneyValue - (double.tryParse(_amountController.text) ?? 0.0);
    double remainingZcoinsAfterWithdrawal = _totalZcoins -
        ((double.tryParse(_amountController.text) ?? 0.0) / _conversionRate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Money Withdrawal', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/mainscreen.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                            'Available Balance: \$${_realMoneyValue.toStringAsFixed(2)} (${_totalZcoins.toStringAsFixed(0)} ƵCoins)',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ),
                      Slider(
                        min: 0,
                        max: 100,
                        divisions: 100,
                        value: _sliderValue,
                        label: '${_sliderValue.toInt()}%',
                        onChanged: (value) => _updateAmountFromSlider(value),
                        activeColor: Colors.blueGrey,
                        inactiveColor: Colors.blueGrey.withOpacity(0.3),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount to Withdraw (\$)',
                            hintText: 'Enter the amount in dollars',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monetization_on),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            } else if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      Text(
                          'You will withdraw: \$${_amountController.text} (${_sliderValue.toStringAsFixed(0)}% of your balance, ${(_sliderValue / 100 * _totalZcoins).toStringAsFixed(0)} ƵCoins)',
                          style: TextStyle(fontSize: 16)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                            'Remaining Balance: \$${remainingBalanceAfterWithdrawal.toStringAsFixed(2)} (${remainingZcoinsAfterWithdrawal.toStringAsFixed(0)} ƵCoins)',
                            style: TextStyle(
                                fontSize: 16, color: Colors.redAccent)),
                      ),
                      ElevatedButton(
                        onPressed: () => _showPaymentOptions(context),
                        child: Text('Choose Payment Method'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blueGrey,
                          onPrimary: Colors.white,
                          minimumSize: Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class CardPaymentForm extends StatefulWidget {
  final String cardType;
  final double selectedZcoins; // Amount of Zcoins selected for withdrawal
  final double selectedAmountInDollars; // Equivalent amount in real money

  CardPaymentForm({
    Key? key,
    required this.cardType,
    required this.selectedZcoins,
    required this.selectedAmountInDollars,
  }) : super(key: key);

  @override
  _CardPaymentFormState createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<CardPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Add this line

  String _cardNumber = '';
  String _expiryDate = '';
  String _cvv = '';
  String _email = '';
  String _holderName = ''; // Card holder's name
  String _variableSymbol = ''; // Optional variable symbol for the transfer

  Future<void> _showDialog(String title, String content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(content),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      // If the form is not valid, do not proceed with the submission
      return;
    }
    _formKey.currentState!.save(); // Save the form data to the state variables

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final prefs = await SharedPreferences.getInstance();
    String? playerDataString = prefs.getString('playerData');
    Map<String, dynamic> playerData =
        playerDataString != null ? jsonDecode(playerDataString) : {};

    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? jwtToken = await secureStorage.read(key: 'jwtToken');

    // Prepare the request body
    String requestBody = jsonEncode({
      'cardNumber': _cardNumber,
      'expiryDate': _expiryDate,
      'cvv': _cvv,
      'email': _email,
      'holderName': _holderName,
      'variableSymbol': _variableSymbol,
      'playerData': playerData,
      'selectedZcoins': widget.selectedZcoins,
      'selectedAmountInDollars': widget.selectedAmountInDollars,
    });

    // Print the request body for debugging
    print("Request body: $requestBody");

    final response = await http.post(
      Uri.parse('${NgrokManager.ngrokUrl}/api/submitWithdrawal'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'Bearer $jwtToken', // Include the JWT token in the Authorization header
      },
      body: jsonEncode({
        'cardNumber': _cardNumber,
        'expiryDate': _expiryDate,
        'cvv': _cvv,
        'email': _email,
        'holderName': _holderName,
        'variableSymbol': _variableSymbol,
        'playerData': playerData,
        'selectedZcoins': widget.selectedZcoins,
        'selectedAmountInDollars': widget.selectedAmountInDollars,
      }),
    );

    setState(() {
      _isLoading = false; // Hide loading indicator
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double currentTotalWinAmount =
          (playerData['total_win_amount'] as num).toDouble();
      print(data);
      double newTotalWinAmount = currentTotalWinAmount - widget.selectedZcoins;

      playerData['total_win_amount'] = newTotalWinAmount;
      await prefs.setString('playerData', jsonEncode(playerData));

      await _showDialog('Success',
          'Your withdrawal request has been submitted successfully. Your ticket number is ${data['ticketNumber']}.\nNew Total Win Amount: \$${newTotalWinAmount.toStringAsFixed(2)}');
    } else {
      await _showDialog('Failed',
          'Failed to submit withdrawal request. Please try again later.');
    }

    Navigator.of(context)
        .pop(); // Close the CardPaymentForm after dialog confirmation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cardType} Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .stretch, // Ensure the button stretches to match the form width
                    children: [
                      Text(
                        'Withdrawal Amount: ${widget.selectedZcoins.toStringAsFixed(2)} Zcoins (\$${widget.selectedAmountInDollars.toStringAsFixed(2)})',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Holder Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the holder\'s name';
                          }
                          return null;
                        },
                        onSaved: (value) => _holderName = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Card Number'),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 16) {
                            return 'Please enter a valid card number';
                          }
                          return null;
                        },
                        onSaved: (value) => _cardNumber = value!,
                      ),
                      TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !RegExp(r"^(0[1-9]|1[0-2])\/?([0-9]{2})$")
                                  .hasMatch(value)) {
                            return 'Please enter a valid expiry date';
                          }
                          return null;
                        },
                        onSaved: (value) => _expiryDate = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'CVV'),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length != 3) {
                            return 'Please enter a valid CVV';
                          }
                          return null;
                        },
                        onSaved: (value) => _cvv = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Variable Symbol (Optional)'),
                        onSaved: (value) => _variableSymbol = value ?? '',
                      ),
                      SizedBox(
                          height:
                              20), // Add some spacing before the submit button
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                await _submitTicket();
                              },
                        child: Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          primary: Theme.of(context)
                              .primaryColor, // Use the primary color from the app's theme
                          padding: EdgeInsets.symmetric(
                              vertical:
                                  16.0), // Increase button's vertical padding
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
