package com.gg.zmoney

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.games.PlayGamesSdk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gg.zmoney/play_games"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Install the SplashScreen
        installSplashScreen()

        super.onCreate(savedInstanceState)

        // Initialize the Mobile Ads SDK
        MobileAds.initialize(this) {}

        // Initialize Play Games SDK
        PlayGamesSdk.initialize(this)

        // Set up the method channel
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "isAuthenticated") {
                // Implement the logic to check if the user is authenticated with Play Games
                // This is where you interact with the Play Games Services SDK
                // For now, let's return a dummy value
                val isAuthenticated = false // Replace with actual authentication logic
                result.success(isAuthenticated)
            } else {
                result.notImplemented()
            }
        }
    }
}
