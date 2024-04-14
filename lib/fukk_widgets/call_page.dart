import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CallPage extends StatefulWidget {
  @override
  CallPageState createState() => CallPageState();
}

class CallPageState extends State<CallPage> {
  final _numberController = TextEditingController();
  int _numberOfCalls = 12; // Default to 1 attempt
  final _formKey = GlobalKey<FormState>();
  static const platform = MethodChannel('com.gg.zmoney/call_control');
  double _callDelay = 4; // Initial delay in seconds

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    //_promptSetDefaultDialer();
  }

  Future<void> _promptSetDefaultDialer() async {
    try {
      final bool? result =
          await platform.invokeMethod('promptSetDefaultDialer');
      if (result == true) {
        print('Requested to set default dialer');
      } else {
        print('User chose not to set default dialer or an error occurred');
      }
    } on PlatformException catch (e) {
      print('Failed to prompt for default dialer: ${e.message}');
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.phone,
    ].request();
  }

  Future<void> _makeCall() async {
    if (_formKey.currentState!.validate()) {
      String number = _numberController.text;

      for (int i = 0; i < 3; i++) {
        // Step 1: Use the method channel to initiate the phone call
        final bool? callInitiated =
            await platform.invokeMethod('initiateCall', {'number': number});
        await Future.delayed(Duration(seconds: _callDelay.toInt()));
        if (callInitiated == true) {
          // Step 2: Listen for a signal that the call is connected
          platform.setMethodCallHandler((call) async {
            if (call.method == "callConnected") {
              // Step 3: Attempt to end the call once connected
              await _killCall();
            }
          });
        } else {
          _showDialog('Error', 'Could not initiate the phone call.');
          return; // Exit if the call initiation fails
        }
        await _killCall();
        // Optionally, wait a bit before initiating the next call
        await Future.delayed(Duration(seconds: (_callDelay / 4).toInt()));
      }
    }
  }

  Future<void> _listenForCallStates() async {
    // Listen for callConnected signal from native side
    platform.setMethodCallHandler((call) async {
      if (call.method == "callConnected") {
        print("Call is now connected, attempting to end call");

        // Wait a brief moment to simulate call duration
        await Future.delayed(Duration(seconds: 2));

        // Attempt to end the call using the method channel
        await _killCall();
      }
    });
  }

  Future<void> _killCall() async {
    try {
      final bool? result = await platform.invokeMethod('killCall');
      if (result == true) {
        print("Call ended successfully");
      } else {
        _showDialog('Error', 'Could not end the phone call.');
      }
    } on PlatformException catch (e) {
      _showDialog('Error', 'Failed to end the phone call: ${e.message}');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
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
        title: Text('Phone Call Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // To avoid overflow when keyboard appears
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Adjust alignment as needed
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      flex: 2, // Adjust the ratio based on your needs
                      child: TextFormField(
                        controller: _numberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Enter Phone Number',
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a phone number'
                            : null,
                      ),
                    ),
                    SizedBox(width: 20), // Provide spacing between elements

                    Expanded(
                      flex: 1, // Adjust the ratio based on your needs
                      child: ElevatedButton(
                        onPressed: _makeCall,
                        child: Text('Make Call'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Spacing between rows
                Text("Number of Calls:"),
                Container(
                  height: 100, // Adjust height as needed
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40.0,
                    diameterRatio: 1.5, // Adjust for a more compact look
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildLoopingListDelegate(
                      children: List<Widget>.generate(
                        10,
                        (index) => Center(child: Text("${index + 1}")),
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _numberOfCalls = index + 1;
                      });
                    },
                  ),
                ),
                Slider(
                  value: _callDelay,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _callDelay.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _callDelay = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
