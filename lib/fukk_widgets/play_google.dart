import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class PlayGoogle {
  static const _platform = MethodChannel('com.gg.zmoney/game_services');

  static Future<void> unlockAchievement(String achievementId) async {
    try {
      final bool result = await _platform
          .invokeMethod('unlockAchievement', {'achievementId': achievementId});
      if (kDebugMode) {
        print("Achievement unlocked: $result");
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to unlock achievement: ${e.message}');
      }
    }
  }
}
