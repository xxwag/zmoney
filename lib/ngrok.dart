import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_handler.dart';

class NgrokManager {
  static String ngrokUrl = '';
  static const secureStorage = FlutterSecureStorage();

  static Future<String?> _getNgrokToken() async {
    try {
      return await secureStorage.read(key: 'ngrokToken');
    } catch (e) {
      // Handle error or return a default value
      return null;
    }
  }

  static Future<void> fetchNgrokData() async {
    if (kDebugMode) {
      print("fetching ngrok data");
    }
    const apiUrl = 'https://api.ngrok.com/tunnels';
    try {
      final String? authToken = await _getNgrokToken();
      if (authToken == null) {
        throw Exception('Ngrok auth token not found');
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Ngrok-Version': '2',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final tunnels = jsonResponse['tunnels'] as List<dynamic>;
        if (tunnels.isNotEmpty) {
          final tunnel = tunnels[0] as Map<String, dynamic>;
          final publicUrl = tunnel['public_url'] as String;

          NotificationHandler.showNotification(
              'Ngrok URL Fetched', 'apiBaseUrl updated to: $publicUrl');

          ngrokUrl = publicUrl;
        } else {
          NotificationHandler.showNotification('No Ngrok Tunnel',
              'No tunnel is currently running, contact your administrator');
        }
      } else {
        NotificationHandler.showNotification(
            'Error', 'Could not initialize ngrok tunnel.');
      }
    } catch (e) {
      NotificationHandler.showNotification(
          'Error', 'Could not fetch ngrok data: $e');
    }
  }
}
