import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  static Future<bool> fetchNgrokData2() async {
    if (kDebugMode) {
      print("fetching ngrok data with Dio");
    }
    const apiUrl = 'https://api.ngrok.com/tunnels';
    try {
      final String? authToken = await _getNgrokToken();
      if (authToken == null) {
        throw Exception('Ngrok auth token not found');
      }

      final dio = Dio();
      final response = await dio.get(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Ngrok-Version': '2',
          },
        ),
      );

      if (response.statusCode == 200) {
        final tunnels = response.data['tunnels'] as List<dynamic>;
        if (tunnels.isNotEmpty) {
          final tunnel = tunnels[0] as Map<String, dynamic>;
          final publicUrl = tunnel['public_url'] as String;

          NotificationHandler.showNotification(
              'Ngrok URL Fetched', 'apiBaseUrl updated to: $publicUrl');

          ngrokUrl = publicUrl;

          return true; // Successfully fetched the URL
        } else {
          NotificationHandler.showNotification('No Ngrok Tunnel',
              'No tunnel is currently running, contact your administrator');
          return false; // No tunnel running
        }
      } else {
        NotificationHandler.showNotification(
            'Error', 'Could not initialize ngrok tunnel.');
        return false; // Error in initializing ngrok tunnel
      }
    } catch (e) {
      NotificationHandler.showNotification(
          'Error', 'Could not fetch ngrok data: $e');
      return false; // Exception occurred
    }
  }

  static Future<void> fetchNgrokData() async {
    if (kDebugMode) {
      print("fetching ngrok data with Dio");
    }
    const apiUrl = 'https://api.ngrok.com/tunnels';
    try {
      final String? authToken = await _getNgrokToken();
      if (authToken == null) {
        throw Exception('Ngrok auth token not found');
      }

      final dio = Dio();
      final response = await dio.get(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Ngrok-Version': '2',
          },
        ),
      );

      if (response.statusCode == 200) {
        final tunnels = response.data['tunnels'] as List<dynamic>;
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
