import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class CallPage extends StatefulWidget {
  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _numberController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Added for form validation

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _makeCall() async {
    if (_formKey.currentState!.validate()) {
      String number = _numberController.text;
      // First call attempt
      bool? firstCallResult = await FlutterPhoneDirectCaller.callNumber(number);
      if (firstCallResult == null || !firstCallResult) {
        _showDialog('Error', 'Could not make the first phone call.');
        return;
      }

      // Optionally, introduce a delay if needed (e.g., to wait for UI updates)
      // await Future.delayed(Duration(seconds: 1));

      // Second call attempt, immediately after the first
      bool? secondCallResult =
          await FlutterPhoneDirectCaller.callNumber(number);
      if (secondCallResult == null || !secondCallResult) {
        _showDialog('Error', 'Could not make the second phone call.');
      }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Enter Phone Number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  // Additional validation for phone number format can be added here
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _makeCall,
                child: Text('Make Call'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
