import 'package:http/http.dart' as http;
import 'dart:convert';

/*Future<Map<String, dynamic>> fetchUserDetails() async {
  // Fetch IP Address
  String ipAddress = await fetchIPAddress();

  // Fetch Device Information
  //Map<String, dynamic> deviceInfo = await getDeviceInfo();

  // Combine and return the data
  return {
    "ipAddress": ipAddress,
    ...deviceInfo,
  };
}
*/
Future<String> fetchIPAddress() async {
  final response =
      await http.get(Uri.parse('https://api.ipify.org?format=json'));
  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse['ip'];
  } else {
    // Handle error
    throw Exception('Failed to load IP address');
  }
}


// DEAD CODE Z LANDING PAGE 

/*
  Future<Map<String, dynamic>> requestToken() async {
    // Ensure Ngrok URL is fetched and updated
    await NgrokManager.fetchNgrokData();

    // Check if Ngrok URL is available
    if (NgrokManager.ngrokUrl.isEmpty) {
      // Handle error: Ngrok URL not available
      throw Exception('Ngrok URL is not available');
    }

    // Collect user details
    Map<String, dynamic> userDetails = await fetchUserDetails();

    // Collect device information
    Map<String, dynamic> deviceInfo = await getDeviceInfo();

    // Fetch the app verification hash from environment variables
    String appVerificationHash =
        FlutterConfig.get('APP_VERIFICATION_HASH').toString();

    // Prepare the request payload with additional device information
    Map<String, dynamic> payload = {
      "userDetails": userDetails,
      "deviceInfo": deviceInfo,
      "appVerification": appVerificationHash,
      // Add any other necessary data
    };

    // Make the token request to the server using Ngrok URL
    final response = await http.post(
      Uri.parse('${NgrokManager.ngrokUrl}/api/requestToken'),
      headers: {
        "Content-Type": "application/json",
        // Additional headers as needed
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      // Parse the response and return
      return json.decode(response.body);
    } else {
      // Handle errors
      throw Exception('Failed to request token: ${response.body}');
    }
  }
*/

/*Future<Map<String, dynamic>> getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  Map<String, dynamic> deviceData = {};

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceData = {
      "device": "android",
      "model": androidInfo.model,
      "brand": androidInfo.brand,
      "androidVersion": androidInfo.version.release,
      "product": androidInfo.product,
      "deviceType": androidInfo.device,
      "id": androidInfo.androidId,
      // Add more properties as needed
    };
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceData = {
      "device": "ios",
      "model": iosInfo.utsname.machine,
      "iOSVersion": iosInfo.systemVersion,
      "name": iosInfo.name,
      "identifierForVendor": iosInfo.identifierForVendor,
      // Add more properties as needed
    };
  } else if (Platform.isWindows) {
    // WindowsDeviceInfo is not supported by device_info
    deviceData = {
      "device": "windows",
      // Additional Windows-specific properties (if any available libraries or methods)
    };
  } else if (Platform.isLinux) {
    // LinuxDeviceInfo is not supported by device_info
    deviceData = {
      "device": "linux",
      // Additional Linux-specific properties (if any available libraries or methods)
    };
  } else if (Platform.isMacOS) {
    // MacOSDeviceInfo is not supported by device_info
    deviceData = {
      "device": "macOS",
      // Additional macOS-specific properties (if any available libraries or methods)
    };
  } else if (Platform.isFuchsia) {
    deviceData = {
      "device": "fuchsia",
      // Fuchsia-specific properties
    };
  }

  return deviceData;
}
*/